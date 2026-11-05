import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/models/burndown_snapshot.dart';
import 'package:ollie/models/sprint.dart';
import 'package:ollie/models/time_log.dart';
import 'package:ollie/repositories/local/local_board_repository.dart';
import 'package:ollie/repositories/local/local_sprint_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late LocalBoardRepository boardRepo;
  late LocalSprintRepository sprintRepo;

  setUp(() async {
    boardRepo = await setUpTestDatabase();
    sprintRepo = LocalSprintRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  Future<String> createTestBoard() async {
    final board = await boardRepo.createBoard(testBoard());
    return board.id;
  }

  TimeLog logFor(
    String cardId, {
    int minutes = 60,
    String? sprintId,
    bool active = false,
  }) {
    final now = DateTime.now();
    return TimeLog(
      id: '',
      cardId: cardId,
      startTime: now.subtract(Duration(minutes: minutes)),
      endTime: active ? null : now,
      durationMinutes: active ? 0 : minutes,
      isActive: active,
      sprintId: sprintId,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('LocalSprintRepository sprints', () {
    test('creates and retrieves sprint', () async {
      final boardId = await createTestBoard();
      final created = await sprintRepo.createSprint(
        testSprint(boardId: boardId, name: 'Sprint A'),
      );

      final fetched = await sprintRepo.getSprint(created.id);
      expect(fetched.name, 'Sprint A');
      expect(fetched.boardId, boardId);
    });

    test('lists sprints by board', () async {
      final boardId = await createTestBoard();
      await sprintRepo.createSprint(testSprint(boardId: boardId, name: 'One'));
      await sprintRepo.createSprint(testSprint(boardId: boardId, name: 'Two'));

      final sprints = await sprintRepo.getSprintsByBoard(boardId);
      expect(sprints.length, 2);
    });

    test('finds active sprint', () async {
      final boardId = await createTestBoard();
      await sprintRepo.createSprint(
        testSprint(
          boardId: boardId,
          name: 'Planning',
          status: SprintStatus.planning,
        ),
      );
      await sprintRepo.createSprint(
        testSprint(
          boardId: boardId,
          name: 'Active',
          status: SprintStatus.active,
        ),
      );

      final active = await sprintRepo.getActiveSprint(boardId);
      expect(active?.name, 'Active');
    });

    test('updates and deletes sprint', () async {
      final boardId = await createTestBoard();
      final sprint = await sprintRepo.createSprint(
        testSprint(boardId: boardId),
      );

      final updated = await sprintRepo.updateSprint(
        sprint.copyWith(name: 'Renamed', status: SprintStatus.completed),
      );
      expect(updated.name, 'Renamed');
      expect(updated.status, SprintStatus.completed);

      await sprintRepo.deleteSprint(sprint.id);
      expect(sprintRepo.getSprint(sprint.id), throwsException);
    });

    test('card membership is derived from cards.sprint_id', () async {
      final seed = await seedBoardWithColumn(boardRepo);
      final sprint = await sprintRepo.createSprint(
        testSprint(boardId: seed.boardId),
      );
      final card = await boardRepo.createCard(
        testCard(columnId: seed.columnId),
      );

      await sprintRepo.addCardToSprint(sprint.id, card.id);
      final fetched = await sprintRepo.getSprint(sprint.id);
      expect(fetched.cardIds, [card.id]);
      expect((await boardRepo.getCard(card.id)).sprintId, sprint.id);

      final listed = await sprintRepo.getSprintsByBoard(seed.boardId);
      expect(listed.single.cardIds, [card.id]);

      await sprintRepo.removeCardFromSprint(sprint.id, card.id);
      expect((await sprintRepo.getSprint(sprint.id)).cardIds, isEmpty);
      expect((await boardRepo.getCard(card.id)).sprintId, isNull);
    });

    test('deleting a sprint clears card and time-log references', () async {
      final seed = await seedBoardWithColumn(boardRepo);
      final sprint = await sprintRepo.createSprint(
        testSprint(boardId: seed.boardId),
      );
      final card = await boardRepo.createCard(
        testCard(columnId: seed.columnId, sprintId: sprint.id),
      );
      final log = await sprintRepo.createTimeLog(
        logFor(card.id, sprintId: sprint.id),
      );

      await sprintRepo.deleteSprint(sprint.id);

      expect((await boardRepo.getCard(card.id)).sprintId, isNull);
      expect((await sprintRepo.getTimeLog(log.id)).sprintId, isNull);
    });
  });

  group('LocalSprintRepository time logs', () {
    test('creates and lists time logs by card', () async {
      final seed = await seedBoardWithColumn(boardRepo);
      final card = await boardRepo.createCard(
        testCard(columnId: seed.columnId),
      );
      final sprint = await sprintRepo.createSprint(
        testSprint(boardId: seed.boardId),
      );

      await sprintRepo.createTimeLog(
        logFor(card.id, minutes: 90, sprintId: sprint.id),
      );

      final logs = await sprintRepo.getTimeLogsByCard(card.id);
      expect(logs.length, 1);
      expect(logs.first.durationMinutes, 90);
    });

    test('keeps card total_logged_hours in sync', () async {
      final seed = await seedBoardWithColumn(boardRepo);
      final card = await boardRepo.createCard(
        testCard(columnId: seed.columnId),
      );

      final first = await sprintRepo.createTimeLog(
        logFor(card.id, minutes: 60),
      );
      expect((await boardRepo.getCard(card.id)).totalLoggedHours, 1.0);

      final second = await sprintRepo.createTimeLog(
        logFor(card.id, minutes: 30),
      );
      expect((await boardRepo.getCard(card.id)).totalLoggedHours, 1.5);

      await sprintRepo.updateTimeLog(second.copyWith(durationMinutes: 90));
      expect((await boardRepo.getCard(card.id)).totalLoggedHours, 2.5);

      await sprintRepo.deleteTimeLog(first.id);
      expect((await boardRepo.getCard(card.id)).totalLoggedHours, 1.5);

      await sprintRepo.deleteTimeLog(second.id);
      expect((await boardRepo.getCard(card.id)).totalLoggedHours, 0.0);
    });

    test('lists logs by sprint', () async {
      final seed = await seedBoardWithColumn(boardRepo);
      final card = await boardRepo.createCard(
        testCard(columnId: seed.columnId),
      );
      final sprint = await sprintRepo.createSprint(
        testSprint(boardId: seed.boardId),
      );
      await sprintRepo.createTimeLog(logFor(card.id, sprintId: sprint.id));

      expect((await sprintRepo.getTimeLogsBySprint(sprint.id)).length, 1);
    });
  });

  group('LocalSprintRepository burndown snapshots', () {
    test('creates and lists snapshots', () async {
      final boardId = await createTestBoard();
      final sprint = await sprintRepo.createSprint(
        testSprint(boardId: boardId),
      );

      await sprintRepo.createBurndownSnapshot(
        BurndownSnapshot(
          id: '',
          sprintId: sprint.id,
          date: DateTime.parse('2025-01-01T00:00:00Z'),
          remainingHours: 40,
          completedHours: 10,
          totalCards: 5,
          completedCards: 1,
          createdAt: DateTime.now(),
        ),
      );

      final snapshots = await sprintRepo.getBurndownSnapshotsBySprint(
        sprint.id,
      );
      expect(snapshots.length, 1);
      expect(snapshots.first.remainingHours, 40);
    });
  });
}
