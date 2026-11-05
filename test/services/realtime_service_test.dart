import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/services/local_change_bus.dart';
import 'package:ollie/services/realtime_service.dart';

void main() {
  group('LocalChangeBus', () {
    test('broadcasts events to listeners', () async {
      final events = <RealtimeEvent>[];
      final sub = LocalChangeBus.instance.stream.listen(events.add);

      LocalChangeBus.instance.emit(
        type: RealtimeEventType.create,
        collection: 'cards',
        documentId: 'card-1',
        data: {'title': 'Test'},
      );

      await Future<void>.delayed(Duration.zero);
      expect(events.length, 1);
      expect(events.first.documentId, 'card-1');
      expect(events.first.type, RealtimeEventType.create);

      await sub.cancel();
    });
  });

  group('RealtimeService', () {
    late RealtimeService service;

    setUp(() {
      service = RealtimeService();
    });

    tearDown(() {
      service.dispose();
    });

    test('receives board events for the matching board only', () async {
      final events = <RealtimeEvent>[];
      final sub = service.subscribeToBoardUpdates('board-1').listen(events.add);

      LocalChangeBus.instance.emit(
        type: RealtimeEventType.update,
        collection: 'boards',
        documentId: 'board-2',
        data: {'name': 'Other'},
      );
      LocalChangeBus.instance.emit(
        type: RealtimeEventType.update,
        collection: 'boards',
        documentId: 'board-1',
        data: {'name': 'Updated'},
      );

      await Future<void>.delayed(Duration.zero);
      expect(events.length, 1);
      expect(events.first.documentId, 'board-1');

      await sub.cancel();
      service.unsubscribeFromBoard('board-1');
    });

    test('filters card and column events by their boardId', () async {
      final events = <RealtimeEvent>[];
      final sub = service.subscribeToBoardUpdates('board-1').listen(events.add);

      LocalChangeBus.instance.emit(
        type: RealtimeEventType.create,
        collection: 'cards',
        documentId: 'card-1',
        data: {'boardId': 'board-2'},
      );
      LocalChangeBus.instance.emit(
        type: RealtimeEventType.create,
        collection: 'columns',
        documentId: 'column-1',
        data: {'boardId': 'board-1'},
      );

      await Future<void>.delayed(Duration.zero);
      expect(events.length, 1);
      expect(events.first.documentId, 'column-1');

      await sub.cancel();
      service.unsubscribeFromBoard('board-1');
    });
  });
}
