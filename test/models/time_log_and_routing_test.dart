import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/models/time_log.dart';
import 'package:ollie/routing/app_route_config.dart';

void main() {
  group('TimeLog', () {
    test('treats year-2099 end time as null', () {
      final log = TimeLog.fromJson({
        'id': 't1',
        'cardId': 'c1',
        'userId': 'local',
        'startTime': '2025-01-01T10:00:00.000Z',
        'endTime': '2099-12-31T00:00:00.000Z',
        'durationMinutes': 0,
        'isActive': true,
        'createdAt': '2025-01-01T10:00:00.000Z',
        'updatedAt': '2025-01-01T10:00:00.000Z',
      });

      expect(log.endTime, isNull);
      expect(log.isActive, isTrue);
    });

    test('formattedDuration shows hours and minutes', () {
      final log = TimeLog(
        id: 't1',
        cardId: 'c1',
        userId: 'local',
        startTime: DateTime.now(),
        durationMinutes: 90,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(log.formattedDuration, '1h 30m');
      expect(log.durationHours, 1.5);
    });
  });

  group('AppRouteConfig', () {
    test('projects page route flags', () {
      final config = AppRouteConfig.projects();
      expect(config.isProjectsPage, isTrue);
      expect(config.isBoardPage, isFalse);
      expect(config.isAuthenticated, isTrue);
    });

    test('board route flags', () {
      final config = AppRouteConfig.board('proj1', 'board1');
      expect(config.isBoardPage, isTrue);
      expect(config.isProjectsPage, isFalse);
      expect(config.selectedBoardId, 'board1');
    });

    test('notFound route flags', () {
      final config = AppRouteConfig.notFound();
      expect(config.show404, isTrue);
      expect(config.isProjectsPage, isFalse);
    });
  });
}
