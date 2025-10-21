import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/board.dart';
import '../models/board_column.dart';
import '../models/card.dart' as model;
import '../models/priority.dart';
import '../repositories/board_repository.dart';
import '../services/realtime_service.dart';
import 'boards_provider.dart';

/// State for a single board with its columns
class BoardState {
  final Board board;
  final List<BoardColumn> columns;
  final Map<String, List<model.Card>> columnCards;
  final bool isLoading;
  final String? errorMessage;

  const BoardState({
    required this.board,
    this.columns = const [],
    this.columnCards = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  BoardState copyWith({
    Board? board,
    List<BoardColumn>? columns,
    Map<String, List<model.Card>>? columnCards,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BoardState(
      board: board ?? this.board,
      columns: columns ?? this.columns,
      columnCards: columnCards ?? this.columnCards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for fetching and managing a single board
final boardProvider = FutureProvider.family<Board, String>((
  ref,
  boardId,
) async {
  final repository = ref.read(boardRepositoryProvider);
  return await repository.getBoard(boardId);
});

/// Provider for fetching columns for a board
final boardColumnsProvider = FutureProvider.family<List<BoardColumn>, String>((
  ref,
  boardId,
) async {
  final repository = ref.read(boardRepositoryProvider);
  return await repository.getColumnsByBoard(boardId);
});

/// Provider for fetching cards for a specific column with real-time updates
final columnCardsProvider = StreamProvider.family<List<model.Card>, String>((
  ref,
  columnId,
) {
  final repository = ref.read(boardRepositoryProvider);
  final realtimeService = ref.read(realtimeServiceProvider);

  return Stream.multi((controller) async {
    // Initial fetch
    try {
      final initialCards = await repository.getCardsByColumn(columnId);
      controller.add(initialCards);
    } catch (e) {
      controller.addError(e);
    }

    // Subscribe to column updates
    final subscription = realtimeService.subscribeToColumn(columnId).listen((
      event,
    ) async {
      // Refetch cards whenever there's a change
      try {
        final updatedCards = await repository.getCardsByColumn(columnId);
        controller.add(updatedCards);
      } catch (e) {
        controller.addError(e);
      }
    }, onError: (error) => controller.addError(error));

    // Cleanup
    controller.onCancel = () {
      subscription.cancel();
      realtimeService.unsubscribeFromColumn(columnId);
    };
  });
});

/// Notifier for managing board state and operations
class BoardNotifier extends StateNotifier<AsyncValue<BoardState>> {
  final BoardRepository _repository;
  final RealtimeService _realtimeService;
  final String _boardId;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  BoardNotifier(this._repository, this._realtimeService, this._boardId)
    : super(const AsyncValue.loading()) {
    _loadBoard();
    _setupRealtimeListener();
  }

  Future<void> _loadBoard() async {
    state = const AsyncValue.loading();
    try {
      final board = await _repository.getBoard(_boardId);
      final columns = await _repository.getColumnsByBoard(_boardId);

      // Fetch cards for each column
      final Map<String, List<model.Card>> columnCards = {};
      for (final column in columns) {
        columnCards[column.id] = await _repository.getCardsByColumn(column.id);
      }

      state = AsyncValue.data(
        BoardState(board: board, columns: columns, columnCards: columnCards),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Setup real-time listener for board updates
  void _setupRealtimeListener() {
    _realtimeSubscription = _realtimeService
        .subscribeToBoardUpdates(_boardId)
        .listen(_handleRealtimeEvent);
  }

  /// Handle real-time events
  void _handleRealtimeEvent(RealtimeEvent event) async {
    if (state is! AsyncData<BoardState>) return;

    final currentState = (state as AsyncData<BoardState>).value;

    try {
      switch (event.collection) {
        case 'boards':
          await _handleBoardEvent(event, currentState);
          break;
        case 'columns':
          await _handleColumnEvent(event, currentState);
          break;
        case 'cards':
          await _handleCardEvent(event, currentState);
          break;
      }
    } catch (e) {
      // Silently handle errors - could add logging here if needed
    }
  }

  Future<void> _handleBoardEvent(
    RealtimeEvent event,
    BoardState currentState,
  ) async {
    if (event.type == RealtimeEventType.update && event.data != null) {
      final updatedBoard = Board.fromJson(event.data!);
      state = AsyncValue.data(currentState.copyWith(board: updatedBoard));
    } else if (event.type == RealtimeEventType.delete) {
      // Board deleted, could navigate away or show error
      state = AsyncValue.error('Board deleted', StackTrace.current);
    }
  }

  Future<void> _handleColumnEvent(
    RealtimeEvent event,
    BoardState currentState,
  ) async {
    final columns = List<BoardColumn>.from(currentState.columns);

    switch (event.type) {
      case RealtimeEventType.create:
        if (event.data != null && event.data!['boardId'] == _boardId) {
          final newColumn = BoardColumn.fromJson(event.data!);
          columns.add(newColumn);
          columns.sort((a, b) => a.position.compareTo(b.position));
          state = AsyncValue.data(currentState.copyWith(columns: columns));
        }
        break;

      case RealtimeEventType.update:
        if (event.data != null) {
          final updatedColumn = BoardColumn.fromJson(event.data!);
          final index = columns.indexWhere((c) => c.id == updatedColumn.id);
          if (index != -1) {
            columns[index] = updatedColumn;
            columns.sort((a, b) => a.position.compareTo(b.position));
            state = AsyncValue.data(currentState.copyWith(columns: columns));
          }
        }
        break;

      case RealtimeEventType.delete:
        columns.removeWhere((c) => c.id == event.documentId);
        state = AsyncValue.data(currentState.copyWith(columns: columns));
        break;
    }
  }

  Future<void> _handleCardEvent(
    RealtimeEvent event,
    BoardState currentState,
  ) async {
    // For card events, we just need to invalidate the affected column
    // The columnCardsProvider will handle fetching the updated cards
    // This is a simple notification that something changed

    // We could implement an in-memory card cache here if needed
    // For now, we let the column provider refetch when cards change
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.unsubscribeFromBoard(_boardId);
    super.dispose();
  }

  /// Manually refresh board data (for operations that might not trigger real-time updates immediately)
  Future<void> refreshBoard() async {
    if (state is! AsyncData<BoardState>) return;

    try {
      final board = await _repository.getBoard(_boardId);
      final currentState = (state as AsyncData<BoardState>).value;
      state = AsyncValue.data(currentState.copyWith(board: board));
    } catch (e) {
      // Keep current state on error
    }
  }

  /// Create a new column
  Future<BoardColumn?> createColumn({
    required String name,
    required int color,
    int? wipLimit,
  }) async {
    if (state is! AsyncData<BoardState>) return null;

    final currentState = (state as AsyncData<BoardState>).value;

    try {
      final newColumn = BoardColumn(
        id: '',
        boardId: _boardId,
        name: name,
        position: currentState.columns.length,
        color: color,
        wipLimit: wipLimit,
        cardIds: [],
      );

      final created = await _repository.createColumn(newColumn);
      // Real-time listener will handle updating the state
      return created;
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(
          errorMessage: 'Failed to create column: ${e.toString()}',
        ),
      );

      return null;
    }
  }

  Future<void> updateColumn(BoardColumn column) async {
    if (state is! AsyncData<BoardState>) return;

    try {
      await _repository.updateColumn(column);
      // Real-time listener will handle updating the state
    } catch (e) {
      final currentState = (state as AsyncData<BoardState>).value;
      state = AsyncValue.data(
        currentState.copyWith(
          errorMessage: 'Failed to update column: ${e.toString()}',
        ),
      );
    }
  }

  /// Delete a column
  Future<void> deleteColumn(String columnId) async {
    if (state is! AsyncData<BoardState>) return;

    try {
      await _repository.deleteColumn(columnId);
      // Real-time listener will handle updating the state
    } catch (e) {
      print(e);
      final currentState = (state as AsyncData<BoardState>).value;
      state = AsyncValue.data(
        currentState.copyWith(
          errorMessage: 'Failed to delete column: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> deleteCard(String cardId) async {
    if (state is! AsyncData<BoardState>) return;
    final originalState = state.asData!.value;

    // Find which column the card is in.
    String? sourceColumnId;
    originalState.columnCards.forEach((colId, cards) {
      if (cards.any((c) => c.id == cardId)) {
        sourceColumnId = colId;
      }
    });

    if (sourceColumnId == null) {
      print("Card not found in local state, cannot delete.");
      return; // Card not found
    }

    // --- Optimistic Update ---
    final newCardsByColumn = Map<String, List<model.Card>>.from(
      originalState.columnCards,
    );
    final sourceList = List<model.Card>.from(newCardsByColumn[sourceColumnId]!);
    sourceList.removeWhere((c) => c.id == cardId);
    newCardsByColumn[sourceColumnId!] = sourceList;

    state = AsyncValue.data(
      originalState.copyWith(columnCards: newCardsByColumn),
    );

    // --- Sync with Server ---
    try {
      await _repository.deleteCard(cardId);
    } catch (e) {
      // On failure, roll back to the original state.
      state = AsyncValue.data(originalState);
      print("Failed to delete card, rolling back. Error: $e");
    }
  }

  /// Update a card with new properties using a more scalable approach.
  Future<void> updateCard({required model.Card updatedCard}) async {
    if (state is! AsyncData<BoardState>) return;
    final originalState = state.asData!.value;

    final columnId = updatedCard.columnId;

    // Find the index of the card to be updated.
    final cardList = List<model.Card>.from(
      originalState.columnCards[columnId] ?? [],
    );
    final cardIndex = cardList.indexWhere((c) => c.id == updatedCard.id);

    if (cardIndex == -1) {
      print("Card to update not found in local state.");
      return; // Card not found
    }

    // --- Optimistic Update ---
    final newCardsByColumn = Map<String, List<model.Card>>.from(
      originalState.columnCards,
    );
    final newCardList = List<model.Card>.from(newCardsByColumn[columnId]!);

    // Replace the old card with the updated card.
    newCardList[cardIndex] = updatedCard;
    newCardsByColumn[columnId] = newCardList;

    // Update the UI immediately.
    state = AsyncValue.data(
      originalState.copyWith(columnCards: newCardsByColumn),
    );

    // --- Sync with Server ---
    try {
      await _repository.updateCard(updatedCard);
    } catch (e) {
      // On failure, roll back to the original state.
      state = AsyncValue.data(originalState);
      print("Failed to update card, rolling back. Error: $e");
    }
  }

  /// Move a card to a different column
  Future<void> moveCard({
    required model.Card card,
    required String targetColumnId,
    required int targetPosition,
  }) async {
    if (state is! AsyncData<BoardState>) return;
    final originalState = state.asData!.value;

    String sourceColumnId = '';
    model.Card? cardToMove;

    originalState.columnCards.forEach((colId, cards) {
      final _card = cards.firstWhere(
        (c) => c.id == card.id,
        orElse: () => model.Card.empty(),
      );
      if (_card.id.isNotEmpty) {
        sourceColumnId = colId;
        cardToMove = card;
      }
    });

    if (cardToMove == null) return;

    final newCardsByColumn = Map<String, List<model.Card>>.from(
      originalState.columnCards,
    );
    final sourceList = List<model.Card>.from(newCardsByColumn[sourceColumnId]!);
    final targetList = sourceColumnId == targetColumnId
        ? sourceList
        : List<model.Card>.from(newCardsByColumn[targetColumnId]!);

    sourceList.removeWhere((c) => c.id == card.id);

    final adjustedPosition = targetPosition.clamp(0, targetList.length);
    targetList.insert(adjustedPosition, card);

    newCardsByColumn[sourceColumnId] = sourceList;
    newCardsByColumn[targetColumnId] = targetList;

    state = AsyncValue.data(
      originalState.copyWith(columnCards: newCardsByColumn),
    );

    try {
      await _repository.moveCard(
        cardId: card.id,
        sourceColumnId: sourceColumnId,
        targetColumnId: targetColumnId,
        targetPosition: adjustedPosition,
      );
    } catch (e) {
      state = AsyncValue.data(originalState);
      print("Failed to move card, rolling back UI. Error: $e");
    }
  }

  /// Create a new card in a column
  Future<model.Card?> createCard({
    required String columnId,
    required String title,
    String? description,
    required Priority priority,
    required String createdBy,
  }) async {
    if (state is! AsyncData<BoardState>) return null;
    final originalState = state.asData!.value;

    final newCardData = model.Card(
      id: '',
      columnId: columnId,
      title: title,
      description: description,
      position: 0,
      assigneeIds: [],
      labelIds: [],
      priority: priority,
      dueDate: null,
      commentCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );

    try {
      final createdCard = await _repository.createCard(newCardData);
      if (createdCard == null) return null;

      final newCardsByColumn = Map<String, List<model.Card>>.from(
        originalState.columnCards,
      );
      final targetList = List<model.Card>.from(
        newCardsByColumn[columnId] ?? [],
      );

      targetList.insert(0, createdCard);
      newCardsByColumn[columnId] = targetList;

      state = AsyncValue.data(
        originalState.copyWith(columnCards: newCardsByColumn),
      );

      return createdCard;
    } catch (e) {
      state = AsyncValue.data(
        originalState.copyWith(
          errorMessage: 'Failed to create card: ${e.toString()}',
        ),
      );
      return null;
    }
  }
}

/// Provider for board notifier
final boardNotifierProvider =
    StateNotifierProvider.family<BoardNotifier, AsyncValue<BoardState>, String>(
      (ref, boardId) {
        final repository = ref.read(boardRepositoryProvider);
        final realtimeService = ref.read(realtimeServiceProvider);
        return BoardNotifier(repository, realtimeService, boardId);
      },
    );
