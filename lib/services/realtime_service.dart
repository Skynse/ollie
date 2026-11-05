import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_change_bus.dart';

/// Event types for local database changes.
enum RealtimeEventType { create, update, delete }

/// Event emitted whenever a repository mutates local data.
class RealtimeEvent {
  final RealtimeEventType type;
  final String documentId;
  final Map<String, dynamic>? data;
  final String collection;

  RealtimeEvent({
    required this.type,
    required this.documentId,
    required this.collection,
    this.data,
  });
}

/// Filters the local change bus so each board only receives its own events.
class RealtimeService {
  final Map<String, StreamSubscription<RealtimeEvent>> _subscriptions = {};
  final Map<String, StreamController<RealtimeEvent>> _controllers = {};

  Stream<RealtimeEvent> subscribeToBoardUpdates(String boardId) {
    final key = 'board_$boardId';
    final existing = _controllers[key];
    if (existing != null && !existing.isClosed) return existing.stream;

    final controller = StreamController<RealtimeEvent>.broadcast(sync: true);
    _controllers[key] = controller;

    final subscription = LocalChangeBus.instance.stream
        .where((event) => _isEventRelevantToBoard(event, boardId))
        .listen(controller.add, onError: controller.addError);

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  void unsubscribeFromBoard(String boardId) => _unsubscribe('board_$boardId');

  void _unsubscribe(String key) {
    _subscriptions.remove(key)?.cancel();
    _controllers.remove(key)?.close();
  }

  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _subscriptions.clear();
    _controllers.clear();
  }

  bool _isEventRelevantToBoard(RealtimeEvent event, String boardId) {
    switch (event.collection) {
      case 'boards':
        return event.documentId == boardId;
      case 'columns':
      case 'cards':
        return event.data?['boardId'] == boardId;
      default:
        return false;
    }
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(service.dispose);
  return service;
});
