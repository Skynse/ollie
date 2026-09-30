import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ollie/config/local_user.dart';
import 'package:ollie/models/board.dart';
import 'package:ollie/repositories/local/local_config.dart';
import 'package:ollie/repositories/board_repository.dart';
import 'package:ollie/repositories/user_repository.dart';

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return LocalConfig.createBoardRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return LocalConfig.createUserRepository();
});

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

class BoardsNotifier extends StateNotifier<BoardsState> {
  final BoardRepository _repository;

  BoardsNotifier(this._repository) : super(const BoardsState()) {
    fetchBoards();
  }

  Future<void> fetchBoards() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final boards = await _repository.getAllBoards();
      if (!mounted) return;

      state = state.copyWith(boards: boards, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load boards: ${e.toString()}',
      );
    }
  }

  Future<Board?> createBoard({
    required String name,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final newBoard = Board(
        id: '',
        name: name,
        description: description,
        createdBy: LocalUser.id,
        memberIds: const [LocalUser.id],
        columnIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        archived: false,
      );

      final created = await _repository.createBoard(newBoard);
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

  Future<void> deleteBoard(String boardId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteBoard(boardId);
      await fetchBoards();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete board: ${e.toString()}',
      );
    }
  }

  Future<void> archiveBoard(String boardId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.archiveBoard(boardId);
      await fetchBoards();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to archive board: ${e.toString()}',
      );
    }
  }

  Future<void> unarchiveBoard(String boardId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.unarchiveBoard(boardId);
      await fetchBoards();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to archive board: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final boardsProvider = StateNotifierProvider<BoardsNotifier, BoardsState>((
  ref,
) {
  final repository = ref.watch(boardRepositoryProvider);
  return BoardsNotifier(repository);
});
