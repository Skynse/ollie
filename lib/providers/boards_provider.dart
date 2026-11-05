import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/board.dart';
import '../repositories/board_repository.dart';
import '../repositories/local/local_config.dart';
import '../utils/copy_with.dart';

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return LocalConfig.createBoardRepository();
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
    Object? errorMessage = unset,
  }) {
    return BoardsState(
      boards: boards ?? this.boards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, unset)
          ? this.errorMessage
          : errorMessage as String?,
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
      state = state.copyWith(
        boards: boards,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load boards: $e',
      );
    }
  }

  Future<Board?> createBoard({
    required String name,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final now = DateTime.now();
      final newBoard = Board(
        id: '',
        name: name,
        description: description,
        archived: false,
        createdAt: now,
        updatedAt: now,
      );

      final created = await _repository.createBoard(newBoard);
      await fetchBoards();
      return created;
    } catch (_) {
      if (!mounted) return null;
      state = state.copyWith(isLoading: false);
      return null;
    }
  }

  Future<void> deleteBoard(String boardId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.deleteBoard(boardId);
      await fetchBoards();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> archiveBoard(String boardId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.archiveBoard(boardId);
      await fetchBoards();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> unarchiveBoard(String boardId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.unarchiveBoard(boardId);
      await fetchBoards();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final boardsProvider = StateNotifierProvider<BoardsNotifier, BoardsState>((
  ref,
) {
  final repository = ref.watch(boardRepositoryProvider);
  return BoardsNotifier(repository);
});
