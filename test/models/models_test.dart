import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/models/board.dart';
import 'package:ollie/models/card.dart';
import 'package:ollie/models/priority.dart';
import 'package:ollie/models/sprint.dart';
import 'package:ollie/models/time_log.dart';

void main() {
  group('Board', () {
    test('serializes and deserializes', () {
      final now = DateTime.now();
      final board = Board(
        id: 'b1',
        name: 'Board',
        description: 'Desc',
        archived: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = board.toJson();
      expect(json['archived'], isTrue);
      expect(json['\$createdAt'], isNotNull);

      final parsed = Board.fromJson(json);
      expect(parsed.id, 'b1');
      expect(parsed.name, 'Board');
      expect(parsed.archived, isTrue);
      expect(parsed.description, 'Desc');
    });

    test('copyWith keeps values unless explicitly changed', () {
      final now = DateTime.now();
      final board = Board(
        id: 'b1',
        name: 'Name',
        description: 'Desc',
        archived: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(board.copyWith(name: 'Other').description, 'Desc');
      expect(board.copyWith(description: null).description, isNull);
      expect(board.copyWith(archived: true).archived, isTrue);
    });
  });

  group('Card', () {
    Card card() => Card(
      id: 'c1',
      columnId: 'col1',
      title: 'Card',
      description: 'Desc',
      priority: Priority.high,
      dueDate: DateTime.now(),
      estimatedHours: 4,
      totalLoggedHours: 1.5,
      sprintId: 's1',
      rank: 'U',
      completed: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('serializes and deserializes', () {
      final original = card();
      final parsed = Card.fromJson(original.toJson());

      expect(parsed.id, original.id);
      expect(parsed.columnId, original.columnId);
      expect(parsed.priority, Priority.high);
      expect(parsed.sprintId, 's1');
      expect(parsed.estimatedHours, 4);
      expect(parsed.totalLoggedHours, 1.5);
    });

    test('copyWith can clear nullable fields', () {
      final original = card();
      final cleared = original.copyWith(
        description: null,
        dueDate: null,
        estimatedHours: null,
        sprintId: null,
      );

      expect(cleared.description, isNull);
      expect(cleared.dueDate, isNull);
      expect(cleared.estimatedHours, isNull);
      expect(cleared.sprintId, isNull);
      expect(original.description, 'Desc');
    });

    test('copyWith keeps nullable fields when omitted', () {
      final original = card();
      final updated = original.copyWith(title: 'New');

      expect(updated.description, 'Desc');
      expect(updated.sprintId, 's1');
      expect(updated.dueDate, isNotNull);
    });
  });

  group('Sprint', () {
    test('serializes and deserializes without storing cardIds', () {
      final now = DateTime.now();
      final sprint = Sprint(
        id: 's1',
        boardId: 'b1',
        name: 'Sprint',
        goal: 'Ship it',
        startDate: now,
        endDate: now.add(const Duration(days: 10)),
        targetHours: 40,
        status: SprintStatus.active,
        cardIds: const ['c1'],
        createdAt: now,
        updatedAt: now,
      );

      final json = sprint.toJson();
      expect(json.containsKey('cardIds'), isFalse);

      final parsed = Sprint.fromJson({
        ...json,
        'cardIds': ['c1'],
      });
      expect(parsed.status, SprintStatus.active);
      expect(parsed.cardIds, ['c1']);
      expect(parsed.copyWith(goal: null).goal, isNull);
    });

    test('unknown status falls back to planning', () {
      expect(SprintStatus.fromJson('unknown'), SprintStatus.planning);
    });

    test('progress does not divide by zero', () {
      final now = DateTime.now();
      final sprint = Sprint(
        id: 's1',
        boardId: 'b1',
        name: 'Sprint',
        startDate: now,
        endDate: now,
        targetHours: 1,
        status: SprintStatus.planning,
        createdAt: now,
        updatedAt: now,
      );
      expect(sprint.progress, 0);
    });
  });

  group('TimeLog', () {
    test('treats year-2099 end time as null', () {
      final log = TimeLog.fromJson({
        'id': 't1',
        'cardId': 'c1',
        'startTime': DateTime.now().toIso8601String(),
        'endTime': DateTime(2099, 12, 31).toIso8601String(),
        'durationMinutes': 0,
        'isActive': true,
      });

      expect(log.endTime, isNull);
      expect(log.isActive, isTrue);
    });

    test('formattedDuration shows hours and minutes', () {
      final now = DateTime.now();
      final log = TimeLog(
        id: 't1',
        cardId: 'c1',
        startTime: now,
        endTime: now,
        durationMinutes: 90,
        isActive: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(log.durationHours, 1.5);
      expect(log.formattedDuration, '1h 30m');
      expect(log.copyWith(notes: 'note').notes, 'note');
      expect(log.copyWith(notes: null).notes, isNull);
    });
  });

  group('Priority', () {
    test('round-trips through JSON', () {
      for (final priority in Priority.values) {
        expect(Priority.fromJson(priority.toJson()), priority);
      }
      expect(Priority.fromJson('unknown'), Priority.low);
    });
  });
}
