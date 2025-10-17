import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/board.dart';
import '../models/board_column.dart';
import '../models/card.dart' as model;
import '../models/priority.dart';
import '../repositories/board_repository.dart';
import 'boards_provider.dart';

/// State for a single board with its columns
class BoardState {
  final Board board;
  final List<BoardColumn> columns;
  final bool isLoading;
  final String? errorMessage;

  const BoardState({
    required this.board,
    this.columns = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BoardState copyWith({
    Board? board,
    List<BoardColumn>? columns,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BoardState(
      board: board ?? this.board,
      columns: columns ?? this.columns,
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

/// Provider for fetching cards for a specific column
final columnCardsProvider = FutureProvider.family<List<model.Card>, String>((
  ref,
  columnId,
) async {
  final repository = ref.read(boardRepositoryProvider);
  return await repository.getCardsByColumn(columnId);
});

/// Notifier for managing board state and operations
class BoardNotifier extends StateNotifier<AsyncValue<BoardState>> {
  final BoardRepository _repository;
  final String _boardId;

  BoardNotifier(this._repository, this._boardId)
    : super(const AsyncValue.loading()) {
    _loadBoard();
  }

  Future<void> _loadBoard() async {
    try {
      final board = await _repository.getBoard(_boardId);
      final columns = await _repository.getColumnsByBoard(_boardId);

      state = AsyncValue.data(BoardState(board: board, columns: columns));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh board data
  Future<void> refresh() async {
    await _loadBoard();
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
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

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
      await refresh();
      return created;
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoading: false,
          errorMessage: 'Failed to create column: ${e.toString()}',
        ),
      );

      return null;
    }
  }

  /// Delete a column
  Future<void> deleteColumn(String columnId) async {
    if (state is! AsyncData<BoardState>) return;

    try {
      await _repository.deleteColumn(columnId);
      await refresh();
    } catch (e) {
      final currentState = (state as AsyncData<BoardState>).value;
      state = AsyncValue.data(
        currentState.copyWith(
          errorMessage: 'Failed to delete column: ${e.toString()}',
        ),
      );
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

    final currentState = (state as AsyncData<BoardState>).value;

    try {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));

      final column = currentState.columns.firstWhere((c) => c.id == columnId);

      final newCard = model.Card(
        id: '',
        columnId: columnId,
        title: title,
        description: description,
        position: column.cardIds.length,
        assigneeIds: [],
        labelIds: [],
        priority: priority,
        dueDate: null,
        commentCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: createdBy,
      );

      final created = await _repository.createCard(newCard);
      await refresh();
      return created;
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoading: false,
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
        return BoardNotifier(repository, boardId);
      },
    );
