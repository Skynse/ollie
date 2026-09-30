import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/config/local_user.dart';
import 'package:ollie/models/board.dart';
import 'package:ollie/models/card.dart';
import 'package:ollie/models/priority.dart';
import 'package:ollie/models/sprint.dart';
import 'package:ollie/models/user.dart';

void main() {
  group('Board', () {
    test('serializes and deserializes', () {
      final board = Board(
        id: 'b1',
        name: 'Sprint Board',
        description: 'Desc',
        createdBy: LocalUser.id,
        memberIds: const [LocalUser.id],
        columnIds: const ['c1'],
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-02T00:00:00Z'),
        archived: false,
      );

      final json = {...board.toJson(), 'id': board.id, '\$createdAt': board.createdAt.toIso8601String(), '\$updatedAt': board.updatedAt.toIso8601String()};
      final restored = Board.fromJson(json);

      expect(restored.id, board.id);
      expect(restored.name, board.name);
      expect(restored.memberIds, board.memberIds);
      expect(restored.archived, false);
    });

    test('copyWith updates fields', () {
      final board = Board(
        id: 'b1',
        name: 'Old',
        createdBy: LocalUser.id,
        memberIds: const [],
        columnIds: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        archived: false,
      );

      final updated = board.copyWith(name: 'New', archived: true);
      expect(updated.name, 'New');
      expect(updated.archived, isTrue);
      expect(updated.id, board.id);
    });
  });

  group('Card', () {
    test('serializes and deserializes', () {
      final card = Card(
        id: 'card1',
        columnId: 'col1',
        title: 'Fix bug',
        position: 0,
        assigneeIds: const [LocalUser.id],
        labelIds: const ['l1'],
        priority: Priority.high,
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-02T00:00:00Z'),
        createdBy: LocalUser.id,
        rank: 'U',
        completed: false,
      );

      final json = {
        ...card.toJson(),
        'id': card.id,
        '\$createdAt': card.createdAt.toIso8601String(),
        '\$updatedAt': card.updatedAt.toIso8601String(),
      };
      final restored = Card.fromJson(json);

      expect(restored.title, 'Fix bug');
      expect(restored.priority, Priority.high);
      expect(restored.assigneeIds, [LocalUser.id]);
    });
  });

  group('Sprint', () {
    test('serializes and deserializes', () {
      final sprint = Sprint(
        id: 's1',
        boardId: 'b1',
        name: 'Sprint 1',
        goal: 'Ship MVP',
        startDate: DateTime.parse('2025-01-01T00:00:00Z'),
        endDate: DateTime.parse('2025-01-15T00:00:00Z'),
        targetHours: 80,
        status: SprintStatus.active,
        cardIds: const ['c1'],
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
      );

      final json = {
        ...sprint.toJson(),
        'id': sprint.id,
        '\$createdAt': sprint.createdAt.toIso8601String(),
        '\$updatedAt': sprint.updatedAt.toIso8601String(),
      };
      final restored = Sprint.fromJson(json);

      expect(restored.name, 'Sprint 1');
      expect(restored.status, SprintStatus.active);
      expect(restored.cardIds, ['c1']);
      expect(restored.isActive, isTrue);
    });
  });

  group('Priority', () {
    test('round-trips through JSON', () {
      expect(Priority.fromJson('high'), Priority.high);
      expect(Priority.fromJson('UNKNOWN'), Priority.low);
      expect(Priority.medium.toJson(), 'medium');
    });
  });

  group('User', () {
    test('serializes and deserializes', () {
      final user = User(id: 'u1', name: 'Alice', email: 'alice@test.com');
      final json = Map<String, dynamic>.from({...user.toJson(), 'id': user.id});
      final restored = User.fromJson(json);

      expect(restored.name, 'Alice');
      expect(restored.email, 'alice@test.com');
    });
  });

  group('LocalUser', () {
    test('provides stable local user', () {
      expect(LocalUser.id, 'local');
      expect(LocalUser.user.id, LocalUser.id);
      expect(LocalUser.user.name, 'Me');
    });
  });
}
