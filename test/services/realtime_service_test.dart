import 'dart:async';

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

    test('subscribeToBoardUpdates receives board events', () async {
      final completer = Completer<RealtimeEvent>();

      final sub = service.subscribeToBoardUpdates('board-1').listen(completer.complete);

      LocalChangeBus.instance.emit(
        type: RealtimeEventType.update,
        collection: 'boards',
        documentId: 'board-1',
        data: {'name': 'Updated'},
      );

      final event = await completer.future.timeout(const Duration(seconds: 1));
      expect(event.collection, 'boards');
      expect(event.documentId, 'board-1');

      await sub.cancel();
      service.unsubscribeFromBoard('board-1');
    });

    test('subscribeToCard receives card-specific events', () async {
      final completer = Completer<RealtimeEvent>();

      final sub = service.subscribeToCard('card-99').listen(completer.complete);

      LocalChangeBus.instance.emit(
        type: RealtimeEventType.update,
        collection: 'cards',
        documentId: 'card-99',
        data: {'title': 'Moved'},
      );

      final event = await completer.future.timeout(const Duration(seconds: 1));
      expect(event.documentId, 'card-99');

      await sub.cancel();
      service.unsubscribeFromCard('card-99');
    });

    test('filters out unrelated board card events by collection', () async {
      final events = <RealtimeEvent>[];
      final sub = service.subscribeToCard('card-1').listen(events.add);

      LocalChangeBus.instance.emit(
        type: RealtimeEventType.update,
        collection: 'cards',
        documentId: 'card-2',
        data: {},
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, isEmpty);

      await sub.cancel();
      service.unsubscribeFromCard('card-1');
    });
  });
}
