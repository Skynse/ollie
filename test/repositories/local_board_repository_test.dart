import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/config/local_user.dart';
import 'package:ollie/models/comment.dart';
import 'package:ollie/models/label.dart';
import 'package:ollie/models/priority.dart';
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
      expect(fetched.createdBy, LocalUser.id);
      expect(fetched.memberIds, contains(LocalUser.id));
    });

    test('getAllBoards returns all boards', () async {
      await repo.createBoard(testBoard(name: 'One'));
      await repo.createBoard(testBoard(name: 'Two'));

      final boards = await repo.getAllBoards();
      expect(boards.length, 2);
      expect(boards.map((b) => b.name), containsAll(['One', 'Two']));
    });

    test('updates board name', () async {
      final board = await repo.createBoard(testBoard());
      final updated = await repo.updateBoard(board.copyWith(name: 'Renamed'));

      expect(updated.name, 'Renamed');
      expect((await repo.getBoard(board.id)).name, 'Renamed');
    });

    test('archives and unarchives board', () async {
      final board = await repo.createBoard(testBoard());
      await repo.archiveBoard(board.id);
      expect((await repo.getBoard(board.id)).archived, isTrue);

      await repo.unarchiveBoard(board.id);
      expect((await repo.getBoard(board.id)).archived, isFalse);
    });

    test('deletes board', () async {
      final board = await repo.createBoard(testBoard());
      await repo.deleteBoard(board.id);

      expect(repo.getBoard(board.id), throwsException);
    });
  });

  group('LocalBoardRepository columns', () {
    test('creates columns ordered by position', () async {
      final board = await repo.createBoard(testBoard());
      await repo.createColumn(testColumn(boardId: board.id, name: 'Backlog', position: 0));
      await repo.createColumn(testColumn(boardId: board.id, name: 'Done', position: 1));

      final columns = await repo.getColumnsByBoard(board.id);
      expect(columns.length, 2);
      expect(columns.first.name, 'Backlog');
      expect(columns.last.name, 'Done');
    });

    test('reorders columns', () async {
      final board = await repo.createBoard(testBoard());
      final colA = await repo.createColumn(testColumn(boardId: board.id, name: 'A', position: 0));
      final colB = await repo.createColumn(testColumn(boardId: board.id, name: 'B', position: 1));

      await repo.reorderColumns(board.id, [colB.id, colA.id]);
      final columns = await repo.getColumnsByBoard(board.id);

      expect(columns.first.name, 'B');
      expect(columns.last.name, 'A');
    });
  });

  group('LocalBoardRepository cards', () {
    test('creates and lists cards by column', () async {
      final seed = await seedBoardWithColumn(repo);
      await repo.createCard(testCard(columnId: seed.columnId, title: 'Task A'));
      await repo.createCard(testCard(columnId: seed.columnId, title: 'Task B', rank: 'V'));

      final cards = await repo.getCardsByColumn(seed.columnId);
      expect(cards.length, 2);
      expect(cards.map((c) => c.title), containsAll(['Task A', 'Task B']));
    });

    test('moves card between columns', () async {
      final board = await repo.createBoard(testBoard());
      final colA = await repo.createColumn(testColumn(boardId: board.id, name: 'A'));
      final colB = await repo.createColumn(testColumn(boardId: board.id, name: 'B'));
      final card = await repo.createCard(testCard(columnId: colA.id));

      await repo.moveCard(
        cardId: card.id,
        sourceColumnId: colA.id,
        targetColumnId: colB.id,
        newRank: 'U',
      );

      expect(await repo.getCardsByColumn(colA.id), isEmpty);
      expect((await repo.getCardsByColumn(colB.id)).single.id, card.id);
    });

    test('updates and deletes card', () async {
      final seed = await seedBoardWithColumn(repo);
      final card = await repo.createCard(testCard(columnId: seed.columnId));

      final updated = await repo.updateCard(card.copyWith(title: 'Updated', completed: true));
      expect(updated.title, 'Updated');
      expect(updated.completed, isTrue);

      await repo.deleteCard(card.id);
      expect(await repo.getCardsByColumn(seed.columnId), isEmpty);
    });
  });

  group('LocalBoardRepository labels and comments', () {
    test('creates label for board', () async {
      final board = await repo.createBoard(testBoard());
      final label = await repo.createLabel(
        Label(id: '', boardId: board.id, name: 'Bug', color: 0xFFFF0000),
      );

      final labels = await repo.getLabelsByBoard(board.id);
      expect(labels.single.name, 'Bug');
      expect(labels.single.id, label.id);
    });

    test('creates comment on card', () async {
      final seed = await seedBoardWithColumn(repo);
      final card = await repo.createCard(testCard(columnId: seed.columnId));

      await repo.createComment(
        Comment(
          id: '',
          cardId: card.id,
          userId: LocalUser.id,
          content: 'Looks good',
          createdAt: DateTime.now(),
        ),
      );

      final comments = await repo.getCommentsByCard(card.id);
      expect(comments.single.content, 'Looks good');
    });
  });

  group('LocalBoardRepository realtime events', () {
    test('emits create event when board is created', () async {
      final events = <RealtimeEvent>[];
      final sub = LocalChangeBus.instance.stream.listen(events.add);

      await repo.createBoard(testBoard(name: 'Realtime'));
      await Future<void>.delayed(Duration.zero);

      expect(events, isNotEmpty);
      expect(events.first.type, RealtimeEventType.create);
      expect(events.first.collection, 'boards');

      await sub.cancel();
    });
  });
}
