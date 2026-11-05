import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/models/priority.dart';
import 'package:ollie/providers/board_provider.dart';
import 'package:ollie/providers/boards_provider.dart';
import 'package:ollie/repositories/local/local_board_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late LocalBoardRepository repo;
  late ProviderContainer container;
  late String boardId;
  late String columnId;

  Future<void> waitForBoard(String id) async {
    for (var i = 0; i < 100; i++) {
      if (container.read(boardNotifierProvider(id)).hasValue) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('board did not load');
  }

  setUp(() async {
    repo = await setUpTestDatabase();
    final seed = await seedBoardWithColumn(repo);
    boardId = seed.boardId;
    columnId = seed.columnId;

    container = ProviderContainer(
      overrides: [boardRepositoryProvider.overrideWithValue(repo)],
    );
    // Keep the auto-dispose provider alive for the duration of the test.
    container.listen(boardNotifierProvider(boardId), (_, _) {});
    await waitForBoard(boardId);
  });

  tearDown(() async {
    container.dispose();
    await tearDownTestDatabase();
  });

  test('loads board, columns and cards', () async {
    final state = container.read(boardNotifierProvider(boardId)).value;
    expect(state, isNotNull);
    expect(state!.board.id, boardId);
    expect(state.columns.single.id, columnId);
    expect(state.columnCards[columnId], isEmpty);
  });

  test('createCard inserts at the top and persists', () async {
    final notifier = container.read(boardNotifierProvider(boardId).notifier);
    final first = await notifier.createCard(
      columnId: columnId,
      title: 'First',
      priority: Priority.medium,
    );
    final second = await notifier.createCard(
      columnId: columnId,
      title: 'Second',
      priority: Priority.high,
    );

    expect(first, isNotNull);
    expect(second, isNotNull);

    final state = container.read(boardNotifierProvider(boardId)).value!;
    expect(state.columnCards[columnId]!.map((c) => c.title), [
      'Second',
      'First',
    ]);

    final persisted = await repo.getCardsByColumn(columnId);
    expect(persisted.map((c) => c.title), ['Second', 'First']);
  });

  test('moveCard reorders and persists rank/column', () async {
    final notifier = container.read(boardNotifierProvider(boardId).notifier);
    final first = (await notifier.createCard(
      columnId: columnId,
      title: 'First',
      priority: Priority.low,
    ))!;
    await notifier.createCard(
      columnId: columnId,
      title: 'Second',
      priority: Priority.low,
    );

    await notifier.moveCard(
      card: first,
      targetColumnId: columnId,
      targetPosition: 0,
    );

    final state = container.read(boardNotifierProvider(boardId)).value!;
    expect(state.columnCards[columnId]!.map((c) => c.title), [
      'First',
      'Second',
    ]);

    final persisted = await repo.getCardsByColumn(columnId);
    expect(persisted.map((c) => c.title), ['First', 'Second']);
  });

  test('deleteCard removes the card and persists', () async {
    final notifier = container.read(boardNotifierProvider(boardId).notifier);
    final card = (await notifier.createCard(
      columnId: columnId,
      title: 'Delete me',
      priority: Priority.low,
    ))!;

    await notifier.deleteCard(card.id);

    final state = container.read(boardNotifierProvider(boardId)).value!;
    expect(state.columnCards[columnId], isEmpty);
    expect(await repo.getCardsByColumn(columnId), isEmpty);
  });

  test('rebalanceColumnRanks preserves order', () async {
    final notifier = container.read(boardNotifierProvider(boardId).notifier);
    await notifier.createCard(
      columnId: columnId,
      title: 'One',
      priority: Priority.low,
    );
    await notifier.createCard(
      columnId: columnId,
      title: 'Two',
      priority: Priority.low,
    );
    await notifier.createCard(
      columnId: columnId,
      title: 'Three',
      priority: Priority.low,
    );

    await notifier.rebalanceColumnRanks(columnId);
    await waitForBoard(boardId);

    final state = container.read(boardNotifierProvider(boardId)).value!;
    expect(state.columnCards[columnId]!.map((c) => c.title), [
      'Three',
      'Two',
      'One',
    ]);
    final ranks = state.columnCards[columnId]!.map((c) => c.rank).toList();
    expect(ranks.toSet().length, 3);
  });
}
