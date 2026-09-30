import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_change_bus.dart';

/// Event types for real-time updates
enum RealtimeEventType { create, update, delete }

/// Real-time event data
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

/// Service for managing local database change subscriptions.
class RealtimeService {
  final Map<String, StreamSubscription<RealtimeEvent>> _subscriptions = {};
  final Map<String, StreamController<RealtimeEvent>> _controllers = {};

  Stream<RealtimeEvent> _filteredStream(bool Function(RealtimeEvent) filter) {
    return LocalChangeBus.instance.stream.where(filter);
  }

  Stream<RealtimeEvent> subscribeToBoardUpdates(String boardId) {
    final key = 'board_$boardId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<RealtimeEvent>.broadcast();
    _controllers[key] = controller;

    final subscription = _filteredStream(
      (event) => _isEventRelevantToBoard(event, boardId),
    ).listen(
      controller.add,
      onError: controller.addError,
    );

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  Stream<RealtimeEvent> subscribeToCard(String cardId) {
    final key = 'card_$cardId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<RealtimeEvent>.broadcast();
    _controllers[key] = controller;

    final subscription = _filteredStream(
      (event) => event.collection == 'cards' && event.documentId == cardId,
    ).listen(
      controller.add,
      onError: controller.addError,
    );

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  Stream<RealtimeEvent> subscribeToColumn(String columnId) {
    final key = 'column_$columnId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<RealtimeEvent>.broadcast();
    _controllers[key] = controller;

    final subscription = _filteredStream((event) {
      if (event.collection == 'columns' && event.documentId == columnId) {
        return true;
      }
      return event.collection == 'cards';
    }).listen(
      controller.add,
      onError: controller.addError,
    );

    _subscriptions[key] = subscription;
    return controller.stream;
  }

  void unsubscribeFromBoard(String boardId) => _unsubscribe('board_$boardId');

  void unsubscribeFromCard(String cardId) => _unsubscribe('card_$cardId');

  void unsubscribeFromColumn(String columnId) =>
      _unsubscribe('column_$columnId');

  void _unsubscribe(String key) {
    _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
    _controllers[key]?.close();
    _controllers.remove(key);
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
    if (event.collection == 'boards' && event.documentId == boardId) {
      return true;
    }

    if (event.collection == 'columns' && event.data?['boardId'] == boardId) {
      return true;
    }

    if (event.collection == 'cards') {
      return true;
    }

    return false;
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});
