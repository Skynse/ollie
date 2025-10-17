import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ollie/models/board.dart';
import 'package:ollie/repositories/appwrite/appwrite_config.dart';
import 'package:ollie/repositories/board_repository.dart';
import 'package:ollie/repositories/user_repository.dart';
import 'auth_provider.dart';

/// Repository provider
final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return AppwriteConfig.createBoardRepository();
});

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return AppwriteConfig.createUserRepository();
});

/// Boards state - holds the list of boards for current user
class BoardsState {
  final List<Board> boards;
  final bool isLoading;
  final String? errorMessage;

  const BoardsState({
    this.boards = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BoardsState copyWith({
    List<Board>? boards,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BoardsState(
      boards: boards ?? this.boards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Boards notifier - manages board list state
class BoardsNotifier extends StateNotifier<BoardsState> {
  final BoardRepository _repository;
  final String? _userId;

  BoardsNotifier(this._repository, this._userId) : super(const BoardsState()) {
    // Only fetch if we have a userId - happens ONCE when provider is created
    if (_userId != null) {
      fetchBoards();
    }
  }

  /// Fetch boards for current user - called ONCE on init
  Future<void> fetchBoards() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final boards = await _repository.getBoardsByUser(_userId!);
      state = state.copyWith(boards: boards, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load boards: ${e.toString()}',
      );
    }
  }

  /// Create a new board - called ONLY on user button click
  Future<Board?> createBoard({
    required String name,
    String? description,
  }) async {
    if (_userId == null) return null;

    state = state.copyWith(isLoading: true);
    try {
      final newBoard = Board(
        id: '', // Appwrite generates this
        name: name,
        description: description,
        createdBy: _userId!,
        memberIds: [_userId!],
        columnIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _repository.createBoard(newBoard);

      // Refetch boards after creation (1 request)
      await fetchBoards();

      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create board: ${e.toString()}',
      );
      return null;
    }
  }

  /// Delete a board - called ONLY on user action
  Future<void> deleteBoard(String boardId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteBoard(boardId);
      await fetchBoards(); // Refetch after deletion
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete board: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Boards provider - depends on auth state to get userId
final boardsProvider = StateNotifierProvider<BoardsNotifier, BoardsState>((
  ref,
) {
  final authState = ref.watch(authProvider);
  final repository = ref.watch(boardRepositoryProvider);

  // Only create notifier with userId if authenticated
  return BoardsNotifier(repository, authState.user?.$id);
});
