import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/cursor_position.dart';

class CursorService {
  WebSocketChannel? _channel;
  final Map<String, CursorPosition> _cursors = {};
  final StreamController<Map<String, CursorPosition>> _cursorController =
      StreamController<Map<String, CursorPosition>>.broadcast();

  String? _currentUserId;
  String? _currentBoardId;
  Timer? _updateTimer;
  CursorPosition? _pendingPosition;

  // Update this to your server URL (localhost for dev, Digital Ocean for prod)
  static const String serverUrl = 'wss://137.184.120.233:3000';

  /// Subscribe to cursor updates for a specific board
  void subscribeToBoard(
    String boardId,
    String userId,
    String userName,
    Color color,
  ) {
    if (_currentBoardId == boardId) return;

    unsubscribe();
    _currentBoardId = boardId;
    _currentUserId = userId;
    _cursors.clear();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      // Listen for messages from server
      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            _handleMessage(message);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );

      // Join the board
      _sendMessage({
        'type': 'join-board',
        'boardId': boardId,
        'userId': userId,
        'userName': userName,
        'color': color.value,
      });
    } catch (e) {
      print('Failed to connect to WebSocket server: $e');
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    print('WebSocket received: $type');

    switch (type) {
      case 'cursors-state':
        // Initial state of all cursors
        final cursors = message['cursors'] as Map<String, dynamic>?;
        if (cursors != null) {
          _cursors.clear();
          cursors.forEach((userId, cursorData) {
            final cursor = CursorPosition.fromJson(
              cursorData as Map<String, dynamic>,
            );
            _cursors[userId] = cursor;
          });
          _cursorController.add(Map.from(_cursors));
        }
        break;

      case 'cursor-update':
        // Another user's cursor moved
        final cursorData = message['cursor'] as Map<String, dynamic>?;
        if (cursorData != null) {
          final cursor = CursorPosition.fromJson(cursorData);
          if (cursor.userId != _currentUserId) {
            _cursors[cursor.userId] = cursor;
            _cursorController.add(Map.from(_cursors));
          }
        }
        break;

      case 'cursor-remove':
        // A user disconnected
        final userId = message['userId'] as String?;
        if (userId != null) {
          _cursors.remove(userId);
          _cursorController.add(Map.from(_cursors));
        }
        break;
    }
  }

  /// Update cursor position (throttled)
  void updateCursorPosition(
    String userId,
    String userName,
    double x,
    double y,
    Color color,
  ) {
    if (_currentBoardId == null || _channel == null) return;

    _pendingPosition = CursorPosition(
      userId: userId,
      userName: userName,
      x: x,
      y: y,
      color: color,
    );

    // Light throttle to avoid flooding (16ms = ~60fps)
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 16), () {
      _sendCursorUpdate();
    });
  }

  void _sendCursorUpdate() {
    if (_pendingPosition == null ||
        _currentBoardId == null ||
        _channel == null) {
      return;
    }

    _sendMessage({
      'type': 'cursor-move',
      'boardId': _currentBoardId,
      'userId': _pendingPosition!.userId,
      'userName': _pendingPosition!.userName,
      'x': _pendingPosition!.x,
      'y': _pendingPosition!.y,
      'color': _pendingPosition!.color.value,
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Stream of cursor positions
  Stream<Map<String, CursorPosition>> get cursorStream =>
      _cursorController.stream;

  /// Get current cursors
  Map<String, CursorPosition> get cursors => Map.from(_cursors);

  /// Unsubscribe from current board
  void unsubscribe() {
    if (_currentBoardId != null && _currentUserId != null) {
      _sendMessage({'type': 'leave-board'});
    }

    _channel?.sink.close();
    _channel = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    _currentBoardId = null;
    _pendingPosition = null;
    _cursors.clear();
  }

  /// Dispose the service
  void dispose() {
    unsubscribe();
    _cursorController.close();
  }
}

/// Provider for cursor service
final cursorServiceProvider = Provider<CursorService>((ref) {
  final service = CursorService();
  ref.onDispose(() => service.dispose());
  return service;
});
