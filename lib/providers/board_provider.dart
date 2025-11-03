import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ollie/algos/lexorank.dart';
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
  final Ref _ref;

  BoardNotifier(
    this._repository,
    this._realtimeService,
    this._boardId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
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
    } catch (e, s) {
      print(e);
      print(s);
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
    print('Handling column event');
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
    final newCardsByColumn = Map<String, List<model.Card>>.from(
      currentState.columnCards.map(
        (key, value) => MapEntry(key, List<model.Card>.from(value)),
      ),
    );

    switch (event.type) {
      case RealtimeEventType.create:
        if (event.data != null) {
          final newCard = model.Card.fromJson(event.data!);
          final cardList = newCardsByColumn[newCard.columnId] ?? [];

          // Avoid duplicates if card was already added optimistically
          if (!cardList.any((c) => c.id == newCard.id)) {
            cardList.add(newCard);
            // Sort by rank to maintain proper order
            cardList.sort((a, b) => a.rank.compareTo(b.rank));
            newCardsByColumn[newCard.columnId] = cardList;
            state = AsyncValue.data(
              currentState.copyWith(columnCards: newCardsByColumn),
            );
          }
        }
        break;

      case RealtimeEventType.update:
        if (event.data != null) {
          final updatedCard = model.Card.fromJson(event.data!);

          // Remove the card from its old position in any column
          newCardsByColumn.forEach((_, cards) {
            cards.removeWhere((c) => c.id == updatedCard.id);
          });

          // Add the card to its new column and sort by rank
          final targetList = newCardsByColumn[updatedCard.columnId] ?? [];
          targetList.add(updatedCard);
          // Sort by rank to maintain proper order
          targetList.sort((a, b) => a.rank.compareTo(b.rank));
          newCardsByColumn[updatedCard.columnId] = targetList;

          state = AsyncValue.data(
            currentState.copyWith(columnCards: newCardsByColumn),
          );
        }
        break;

      case RealtimeEventType.delete:
        final cardId = event.documentId;
        String? columnId;

        // Find and remove the card
        for (var entry in newCardsByColumn.entries) {
          final list = entry.value;
          final initialLength = list.length;
          list.removeWhere((c) => c.id == cardId);
          if (list.length < initialLength) {
            columnId = entry.key;
            break;
          }
        }

        if (columnId != null) {
          state = AsyncValue.data(
            currentState.copyWith(columnCards: newCardsByColumn),
          );
        }
        break;
    }
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
    final previousState = state;
    final currentState = state.value;

    if (currentState == null) return;

    final newColumnCards = Map<String, List<model.Card>>.from(
      currentState.columnCards,
    );

    // Locate source column
    final sourceColumnId = newColumnCards.entries
        .firstWhere(
          (entry) => entry.value.any((c) => c.id == card.id),
          orElse: () => const MapEntry('', []),
        )
        .key;

    if (sourceColumnId.isEmpty) return;

    // Clone source list and find original index BEFORE removing
    final sourceCards = List<model.Card>.from(newColumnCards[sourceColumnId]!);
    final originalIndex = sourceCards.indexWhere((c) => c.id == card.id);
    sourceCards.removeWhere((c) => c.id == card.id);

    // Get target cards and sort by rank BEFORE calculating new rank
    final targetCards = List<model.Card>.from(
      newColumnCards[targetColumnId] ?? [],
    );
    // Remove the card from target if it's the same column
    if (sourceColumnId == targetColumnId) {
      targetCards.removeWhere((c) => c.id == card.id);
    }
    targetCards.sort((a, b) => a.rank.compareTo(b.rank));

    // --- LexoRank computation ---
    // For same-column moves, targetPosition is based on the original list (before removal)
    // When moving down, we need to adjust because the card being moved affects indices
    int adjustedPosition = targetPosition;
    if (sourceColumnId == targetColumnId &&
        originalIndex != -1 &&
        targetPosition > originalIndex) {
      // Moving down: the target position included the dragged card's slot, so subtract 1
      adjustedPosition = targetPosition - 1;
    }

    String newRank;
    final clampedPosition = adjustedPosition.clamp(0, targetCards.length);

    if (targetCards.isEmpty) {
      newRank = 'U'; // middle baseline
    } else if (clampedPosition == 0) {
      // Insert at the beginning
      newRank = LexoRank.middle('', targetCards.first.rank);
    } else if (clampedPosition >= targetCards.length) {
      // Insert at the end
      newRank = LexoRank.middle(targetCards.last.rank, '');
    } else {
      // Insert between two cards
      final before = targetCards[clampedPosition - 1].rank;
      final after = targetCards[clampedPosition].rank;
      newRank = LexoRank.middle(before, after);
    }

    // Create the moved card with new rank and columnId
    final movedCard = card.copyWith(columnId: targetColumnId, rank: newRank);

    // Update source and target lists for optimistic UI update
    newColumnCards[sourceColumnId] = sourceCards;
    targetCards.insert(clampedPosition, movedCard);
    newColumnCards[targetColumnId] = targetCards;

    // Optimistically update UI
    state = AsyncValue.data(currentState.copyWith(columnCards: newColumnCards));

    try {
      // --- Persist to backend ---
      await _repository.moveCard(
        cardId: card.id,
        sourceColumnId: sourceColumnId,
        targetColumnId: targetColumnId,
        newRank: newRank,
      );
    } catch (e, st) {
      // Rollback on error
      state = previousState;
      debugPrint('moveCard failed: $e\n$st');
    }
  }

  /// Rebalance ranks for all cards in a column
  /// This fixes duplicate ranks by redistributing them evenly
  Future<void> rebalanceColumnRanks(String columnId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final cards = List<model.Card>.from(
      currentState.columnCards[columnId] ?? [],
    );

    if (cards.length <= 1) return; // Nothing to rebalance

    // Sort by current rank to preserve order
    cards.sort((a, b) => a.rank.compareTo(b.rank));

    // Redistribute ranks evenly across the space
    // Use base-36 arithmetic to create evenly spaced ranks
    final step = 'ZZZZZZZZZZ'; // Max rank value
    final stepNum = LexoRank.toBase36(step) ~/ BigInt.from(cards.length + 1);

    for (int i = 0; i < cards.length; i++) {
      final rankNum = stepNum * BigInt.from(i + 1);
      final newRank = LexoRank.fromBase36(rankNum);

      if (cards[i].rank != newRank) {
        // Update in backend
        try {
          await _repository.moveCard(
            cardId: cards[i].id,
            sourceColumnId: columnId,
            targetColumnId: columnId,
            newRank: newRank,
          );
        } catch (e) {
          debugPrint('Failed to rebalance card ${cards[i].id}: $e');
        }
      }
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

    // Get existing cards and sort by rank to calculate new rank for the top position
    final existingCards = List<model.Card>.from(
      originalState.columnCards[columnId] ?? [],
    );
    existingCards.sort((a, b) => a.rank.compareTo(b.rank));

    // Calculate rank for new card at position 0 (top of column)
    String newRank;
    if (existingCards.isEmpty) {
      newRank = 'U'; // middle baseline
    } else {
      // Insert before the first card
      newRank = LexoRank.middle('', existingCards.first.rank);
    }

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
      rank: newRank,
    );

    try {
      final createdCard = await _repository.createCard(newCardData);

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
        return BoardNotifier(repository, realtimeService, boardId, ref);
      },
    );
