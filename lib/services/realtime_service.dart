import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/appwrite/appwrite_config.dart';

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

  factory RealtimeEvent.fromResponse(RealtimeMessage response) {
    final events = response.events;
    final payload = response.payload;

    RealtimeEventType type;
    if (events.any((e) => e.contains('.create'))) {
      type = RealtimeEventType.create;
    } else if (events.any((e) => e.contains('.delete'))) {
      type = RealtimeEventType.delete;
    } else {
      type = RealtimeEventType.update;
    }

    // Extract collection from event path
    String collection = '';
    for (var event in events) {
      if (event.contains('collections.')) {
        final parts = event.split('.');
        final collectionIndex = parts.indexOf('collections') + 1;
        if (collectionIndex < parts.length) {
          collection = parts[collectionIndex];
        }
      }
    }

    return RealtimeEvent(
      type: type,
      documentId: payload['\$id'] as String? ?? '',
      collection: collection,
      data: payload,
    );
  }
}

/// Service for managing Appwrite real-time subscriptions
class RealtimeService {
  final Realtime _realtime;
  final Map<String, RealtimeSubscription> _subscriptions = {};
  final Map<String, StreamController<RealtimeEvent>> _controllers = {};

  RealtimeService() : _realtime = Realtime(AppwriteConfig.client);

  /// Subscribe to a board's real-time updates (cards, columns, board changes)
  Stream<RealtimeEvent> subscribeToBoardUpdates(String boardId) {
    final key = 'board_$boardId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<RealtimeEvent>.broadcast();
    _controllers[key] = controller;

    final subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.cards.documents',
      'databases.${AppwriteConfig.databaseId}.collections.columns.documents',
      'databases.${AppwriteConfig.databaseId}.collections.boards.documents.$boardId',
    ]);

    subscription.stream.listen(
      (response) {
        final event = RealtimeEvent.fromResponse(response);

        // Only forward events relevant to this board
        if (_isEventRelevantToBoard(event, boardId)) {
          controller.add(event);
        }
      },
      onError: (error) {
        controller.addError(error);
      },
    );

    _subscriptions[key] = subscription;

    return controller.stream;
  }

  /// Subscribe to specific card updates
  Stream<RealtimeEvent> subscribeToCard(String cardId) {
    final key = 'card_$cardId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<RealtimeEvent>.broadcast();
    _controllers[key] = controller;

    final subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.cards.documents.$cardId',
    ]);

    subscription.stream.listen(
      (response) {
        final event = RealtimeEvent.fromResponse(response);
        controller.add(event);
      },
      onError: (error) {
        controller.addError(error);
      },
    );

    _subscriptions[key] = subscription;

    return controller.stream;
  }

  /// Subscribe to column updates
  Stream<RealtimeEvent> subscribeToColumn(String columnId) {
    final key = 'column_$columnId';

    if (_controllers.containsKey(key)) {
      return _controllers[key]!.stream;
    }

    final controller = StreamController<RealtimeEvent>.broadcast();
    _controllers[key] = controller;

    final subscription = _realtime.subscribe([
      'databases.${AppwriteConfig.databaseId}.collections.columns.documents.$columnId',
      'databases.${AppwriteConfig.databaseId}.collections.cards.documents',
    ]);

    subscription.stream.listen(
      (response) {
        final event = RealtimeEvent.fromResponse(response);

        // Forward column updates and cards that belong to this column
        if (event.collection == 'columns' && event.documentId == columnId) {
          controller.add(event);
        } else if (event.collection == 'cards' &&
            event.data?['columnId'] == columnId) {
          controller.add(event);
        }
      },
      onError: (error) {
        controller.addError(error);
      },
    );

    _subscriptions[key] = subscription;

    return controller.stream;
  }

  /// Unsubscribe from board updates
  void unsubscribeFromBoard(String boardId) {
    final key = 'board_$boardId';
    _unsubscribe(key);
  }

  /// Unsubscribe from card updates
  void unsubscribeFromCard(String cardId) {
    final key = 'card_$cardId';
    _unsubscribe(key);
  }

  /// Unsubscribe from column updates
  void unsubscribeFromColumn(String columnId) {
    final key = 'column_$columnId';
    _unsubscribe(key);
  }

  void _unsubscribe(String key) {
    _subscriptions[key]?.close();
    _subscriptions.remove(key);
    _controllers[key]?.close();
    _controllers.remove(key);
  }

  /// Close all subscriptions
  void dispose() {
    for (var subscription in _subscriptions.values) {
      subscription.close();
    }
    for (var controller in _controllers.values) {
      controller.close();
    }
    _subscriptions.clear();
    _controllers.clear();
  }

  /// Check if an event is relevant to a specific board
  bool _isEventRelevantToBoard(RealtimeEvent event, String boardId) {
    // Board updates
    if (event.collection == 'boards' && event.documentId == boardId) {
      return true;
    }

    // Column updates for this board
    if (event.collection == 'columns' && event.data?['boardId'] == boardId) {
      return true;
    }

    // Card updates - we'll need to check if the card belongs to a column in this board
    // For now, we'll let all card events through and filter at the provider level
    if (event.collection == 'cards') {
      return true;
    }

    return false;
  }
}

/// Provider for realtime service
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});
