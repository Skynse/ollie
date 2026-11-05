import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/providers/boards_provider.dart';
import 'package:ollie/repositories/local/local_board_repository.dart';

import '../helpers/test_database.dart';

void main() {
  group('BoardsNotifier', () {
    late LocalBoardRepository repo;
    late ProviderContainer container;

    setUp(() async {
      repo = await setUpTestDatabase();
      container = ProviderContainer(
        overrides: [boardRepositoryProvider.overrideWithValue(repo)],
      );
      await waitForBoardsIdle(container, boardsProvider);
    });

    tearDown(() async {
      container.dispose();
      await tearDownTestDatabase();
    });

    test('loads boards on init', () async {
      await repo.createBoard(testBoard(name: 'Loaded'));
      await container.read(boardsProvider.notifier).fetchBoards();

      final state = container.read(boardsProvider);
      expect(state.isLoading, isFalse);
      expect(state.boards.length, 1);
      expect(state.boards.first.name, 'Loaded');
    });

    test('createBoard adds board and refreshes list', () async {
      final notifier = container.read(boardsProvider.notifier);
      final created = await notifier.createBoard(
        name: 'New Board',
        description: 'Desc',
      );

      expect(created, isNotNull);
      expect(created!.name, 'New Board');

      final state = container.read(boardsProvider);
      expect(state.boards.any((b) => b.name == 'New Board'), isTrue);
      expect(state.isLoading, isFalse);
    });

    test('archiveBoard marks board archived', () async {
      final board = await repo.createBoard(testBoard());
      final notifier = container.read(boardsProvider.notifier);

      await notifier.archiveBoard(board.id);

      final state = container.read(boardsProvider);
      expect(state.boards.length, 1);
      expect(state.boards.first.archived, isTrue);
    });

    test('deleteBoard removes board from list', () async {
      final board = await repo.createBoard(testBoard());
      final notifier = container.read(boardsProvider.notifier);

      await notifier.deleteBoard(board.id);

      final state = container.read(boardsProvider);
      expect(state.boards, isEmpty);
    });

    test('clearError removes error message', () {
      final notifier = container.read(boardsProvider.notifier);
      notifier.clearError();
      expect(container.read(boardsProvider).errorMessage, isNull);
    });
  });
}
