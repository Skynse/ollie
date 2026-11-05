import 'dart:async';

import 'realtime_service.dart';

/// Broadcasts local database changes so UI layers can update without polling.
class LocalChangeBus {
  LocalChangeBus._();

  static final LocalChangeBus instance = LocalChangeBus._();

  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast(sync: true);

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
