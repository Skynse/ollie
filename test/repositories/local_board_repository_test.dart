import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/database/database_helper.dart';
import 'package:ollie/models/checklist.dart';
import 'package:ollie/models/checklist_item.dart';
import 'package:ollie/repositories/local/local_board_repository.dart';
import 'package:ollie/services/local_change_bus.dart';
import 'package:ollie/services/realtime_service.dart';

import '../helpers/test_database.dart';

void main() {
  late LocalBoardRepository repo;

  setUp(() async {
    repo = await setUpTestDatabase();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('LocalBoardRepository boards', () {
    test('creates and retrieves a board', () async {
      final created = await repo.createBoard(testBoard(name: 'Alpha'));
      final fetched = await repo.getBoard(created.id);

      expect(fetched.name, 'Alpha');
      expect(fetched.description, 'A test board');
      expect(fetched.archived, isFalse);
    });

    test('getAllBoards returns all boards', () async {
      await repo.createBoard(testBoard(name: 'One'));
      await repo.createBoard(testBoard(name: 'Two'));

      final boards = await repo.getAllBoards();
      expect(boards.length, 2);
      expect(boards.map((b) => b.name), containsAll(['One', 'Two']));
    });

    test('updates board and clears description with null', () async {
      final board = await repo.createBoard(testBoard());
      final renamed = await repo.updateBoard(
        board.copyWith(name: 'Renamed', description: null),
      );

      expect(renamed.name, 'Renamed');
      expect(renamed.description, isNull);
      expect((await repo.getBoard(board.id)).description, isNull);
    });

    test('archives and unarchives board', () async {
      final board = await repo.createBoard(testBoard());
      await repo.archiveBoard(board.id);
      expect((await repo.getBoard(board.id)).archived, isTrue);

      await repo.unarchiveBoard(board.id);
      expect((await repo.getBoard(board.id)).archived, isFalse);
    });

    test('deletes board and its columns/cards', () async {
      final seed = await seedBoardWithColumn(repo);
      await repo.createCard(testCard(columnId: seed.columnId));

      await repo.deleteBoard(seed.boardId);
      expect(repo.getBoard(seed.boardId), throwsException);
      expect(await repo.getColumnsByBoard(seed.boardId), isEmpty);
    });
  });

  group('LocalBoardRepository columns', () {
    test('creates columns ordered by position', () async {
      final board = await repo.createBoard(testBoard());
      await repo.createColumn(
        testColumn(boardId: board.id, name: 'Backlog', position: 0),
      );
      await repo.createColumn(
        testColumn(boardId: board.id, name: 'Done', position: 1),
      );

      final columns = await repo.getColumnsByBoard(board.id);
      expect(columns.length, 2);
      expect(columns.first.name, 'Backlog');
      expect(columns.last.name, 'Done');
    });

    test('reorders columns', () async {
      final board = await repo.createBoard(testBoard());
      final colA = await repo.createColumn(
        testColumn(boardId: board.id, name: 'A', position: 0),
      );
      final colB = await repo.createColumn(
        testColumn(boardId: board.id, name: 'B', position: 1),
      );

      await repo.reorderColumns(board.id, [colB.id, colA.id]);
      final columns = await repo.getColumnsByBoard(board.id);

      expect(columns.first.name, 'B');
      expect(columns.last.name, 'A');
    });

    test('clears a WIP limit with null', () async {
      final board = await repo.createBoard(testBoard());
      final column = await repo.createColumn(
        testColumn(boardId: board.id, wipLimit: 5),
      );
      final updated = await repo.updateColumn(column.copyWith(wipLimit: null));

      expect(updated.wipLimit, isNull);
    });

    test('deleting a column cascades its cards', () async {
      final seed = await seedBoardWithColumn(repo);
      final card = await repo.createCard(testCard(columnId: seed.columnId));

      await repo.deleteColumn(seed.columnId);
      expect(await repo.getCardsByColumn(seed.columnId), isEmpty);
      expect(repo.getCard(card.id), throwsException);
    });
  });

  group('LocalBoardRepository cards', () {
    test('creates and lists cards by column ordered by rank', () async {
      final seed = await seedBoardWithColumn(repo);
      await repo.createCard(testCard(columnId: seed.columnId, title: 'Task A'));
      await repo.createCard(testCard(columnId: seed.columnId, title: 'Task B'));

      final cards = await repo.getCardsByColumn(seed.columnId);
      expect(cards.length, 2);
      expect(cards.map((c) => c.title), containsAll(['Task A', 'Task B']));
    });

    test('getCardsByBoard returns cards across columns', () async {
      final board = await repo.createBoard(testBoard());
      final colA = await repo.createColumn(testColumn(boardId: board.id));
      final colB = await repo.createColumn(
        testColumn(boardId: board.id, name: 'Doing', position: 1),
      );
      await repo.createCard(testCard(columnId: colA.id));
      await repo.createCard(testCard(columnId: colB.id));

      final cards = await repo.getCardsByBoard(board.id);
      expect(cards.length, 2);
      expect(cards.map((c) => c.columnId), containsAll([colA.id, colB.id]));
    });

    test('moves card between columns', () async {
      final board = await repo.createBoard(testBoard());
      final colA = await repo.createColumn(
        testColumn(boardId: board.id, name: 'A'),
      );
      final colB = await repo.createColumn(
        testColumn(boardId: board.id, name: 'B'),
      );
      final card = await repo.createCard(testCard(columnId: colA.id));

      await repo.moveCard(
        cardId: card.id,
        targetColumnId: colB.id,
        newRank: 'U',
      );

      expect(await repo.getCardsByColumn(colA.id), isEmpty);
      final moved = (await repo.getCardsByColumn(colB.id)).single;
      expect(moved.id, card.id);
      expect(moved.columnId, colB.id);
    });

    test('updates nullable card fields with null', () async {
      final seed = await seedBoardWithColumn(repo);
      final card = await repo.createCard(
        testCard(columnId: seed.columnId).copyWith(
          description: 'hello',
          dueDate: DateTime.now(),
          estimatedHours: 3,
        ),
      );

      final updated = await repo.updateCard(
        card.copyWith(
          description: null,
          dueDate: null,
          estimatedHours: null,
          completed: true,
        ),
      );

      expect(updated.description, isNull);
      expect(updated.dueDate, isNull);
      expect(updated.estimatedHours, isNull);
      expect(updated.completed, isTrue);
    });

    test('deletes card', () async {
      final seed = await seedBoardWithColumn(repo);
      final card = await repo.createCard(testCard(columnId: seed.columnId));

      await repo.deleteCard(card.id);
      expect(await repo.getCardsByColumn(seed.columnId), isEmpty);
      expect(repo.getCard(card.id), throwsException);
    });
  });

  group('LocalBoardRepository checklists', () {
    test('creates, updates and deletes a checklist', () async {
      final seed = await seedBoardWithColumn(repo);
      final card = await repo.createCard(testCard(columnId: seed.columnId));

      final created = await repo.createChecklist(
        Checklist(
          id: '',
          cardId: card.id,
          title: 'Subtasks',
          items: [ChecklistItem(id: '1', text: 'First')],
        ),
      );
      expect(created.items.single.text, 'First');

      final updated = await repo.updateChecklist(
        created.copyWith(
          items: [ChecklistItem(id: '1', text: 'First', isCompleted: true)],
        ),
      );
      expect(updated.items.single.isCompleted, isTrue);

      await repo.deleteChecklist(created.id);
      expect(await repo.getChecklistsByCard(card.id), isEmpty);
    });
  });

  group('LocalBoardRepository realtime events', () {
    test('emits card events tagged with their board', () async {
      final seed = await seedBoardWithColumn(repo);
      final events = <RealtimeEvent>[];
      final sub = LocalChangeBus.instance.stream.listen(events.add);

      await repo.createCard(testCard(columnId: seed.columnId));
      await Future<void>.delayed(Duration.zero);

      final cardEvent = events.firstWhere((e) => e.collection == 'cards');
      expect(cardEvent.type, RealtimeEventType.create);
      expect(cardEvent.data?['boardId'], seed.boardId);
      await sub.cancel();
    });
  });

  group('database schema', () {
    test('uses the local-only version and no collaboration tables', () async {
      final db = await DatabaseHelper.instance.database;
      final version = await db.rawQuery('PRAGMA user_version');
      expect(version.first.values.first, DatabaseHelper.schemaVersion);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.map((row) => row['name'] as String).toSet();
      expect(names, contains('boards'));
      expect(names, contains('cards'));
      expect(names, isNot(contains('users')));
      expect(names, isNot(contains('comments')));
      expect(names, isNot(contains('labels')));
      expect(names, isNot(contains('invitations')));
    });
  });
}
