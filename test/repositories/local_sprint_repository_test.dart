import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/config/local_user.dart';
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
        testSprint(boardId: boardId, name: 'Planning', status: SprintStatus.planning),
      );
      await sprintRepo.createSprint(
        testSprint(boardId: boardId, name: 'Active', status: SprintStatus.active),
      );

      final active = await sprintRepo.getActiveSprint(boardId);
      expect(active?.name, 'Active');
    });

    test('updates and deletes sprint', () async {
      final boardId = await createTestBoard();
      final sprint = await sprintRepo.createSprint(testSprint(boardId: boardId));

      final updated = await sprintRepo.updateSprint(
        sprint.copyWith(name: 'Renamed', status: SprintStatus.completed),
      );
      expect(updated.name, 'Renamed');
      expect(updated.status, SprintStatus.completed);

      await sprintRepo.deleteSprint(sprint.id);
      expect(sprintRepo.getSprint(sprint.id), throwsException);
    });
  });

  group('LocalSprintRepository time logs', () {
    test('creates and lists time logs by card', () async {
      final seed = await seedBoardWithColumn(boardRepo);
      final card = await boardRepo.createCard(testCard(columnId: seed.columnId));
      final boardId = seed.boardId;
      final sprint = await sprintRepo.createSprint(testSprint(boardId: boardId));

      final now = DateTime.now();
      await sprintRepo.createTimeLog(
        TimeLog(
          id: '',
          cardId: card.id,
          userId: LocalUser.id,
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now,
          durationMinutes: 60,
          isActive: false,
          sprintId: sprint.id,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final logs = await sprintRepo.getTimeLogsByCard(card.id);
      expect(logs.length, 1);
      expect(logs.first.durationMinutes, 60);
    });

    test('finds active time log for user', () async {
      final seed = await seedBoardWithColumn(boardRepo);
      final card = await boardRepo.createCard(testCard(columnId: seed.columnId));
      final now = DateTime.now();

      await sprintRepo.createTimeLog(
        TimeLog(
          id: '',
          cardId: card.id,
          userId: LocalUser.id,
          startTime: now,
          durationMinutes: 0,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final active = await sprintRepo.getActiveTimeLog(LocalUser.id);
      expect(active, isNotNull);
      expect(active!.isActive, isTrue);
    });
  });

  group('LocalSprintRepository burndown snapshots', () {
    test('creates and lists snapshots', () async {
      final boardId = await createTestBoard();
      final sprint = await sprintRepo.createSprint(testSprint(boardId: boardId));

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

      final snapshots = await sprintRepo.getBurndownSnapshotsBySprint(sprint.id);
      expect(snapshots.length, 1);
      expect(snapshots.first.remainingHours, 40);
    });
  });
}
