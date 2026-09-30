import 'dart:async';

import '../services/realtime_service.dart';

/// Broadcasts local database changes so UI layers can react like Appwrite realtime.
class LocalChangeBus {
  LocalChangeBus._();

  static final LocalChangeBus instance = LocalChangeBus._();

  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get stream => _controller.stream;

  void emit({
    required RealtimeEventType type,
    required String collection,
    required String documentId,
    Map<String, dynamic>? data,
  }) {
    if (_controller.isClosed) return;
    _controller.add(
      RealtimeEvent(
        type: type,
        documentId: documentId,
        collection: collection,
        data: data,
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}
