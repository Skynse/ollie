import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cursor_position.dart';
import '../services/cursor_service.dart';
import '../repositories/appwrite/appwrite_config.dart';

class MultiplayerCursors extends ConsumerStatefulWidget {
  final String boardId;
  final Widget child;

  const MultiplayerCursors({
    super.key,
    required this.boardId,
    required this.child,
  });

  @override
  ConsumerState<MultiplayerCursors> createState() => _MultiplayerCursorsState();
}

class _MultiplayerCursorsState extends ConsumerState<MultiplayerCursors> {
  final Map<String, CursorPosition> _cursors = {};

  @override
  void initState() {
    super.initState();
    _subscribeToCursors();
  }

  void _subscribeToCursors() {
    final cursorService = ref.read(cursorServiceProvider);
    final currentUser = AppwriteConfig.currentUser;

    if (currentUser != null) {
      final color = _getUserColor(currentUser.$id);
      cursorService.subscribeToBoard(
        widget.boardId,
        currentUser.$id,
        currentUser.name,
        color,
      );

      cursorService.cursorStream.listen((cursors) {
        if (mounted) {
          setState(() {
            _cursors.clear();
            _cursors.addAll(cursors);
          });
        }
      });
    }
  }

  void _onPointerHover(PointerHoverEvent event) {
    final cursorService = ref.read(cursorServiceProvider);
    final currentUser = AppwriteConfig.currentUser;

    if (currentUser != null) {
      final color = _getUserColor(currentUser.$id);

      cursorService.updateCursorPosition(
        currentUser.$id,
        currentUser.name,
        event.position.dx,
        event.position.dy,
        color,
      );
    }
  }

  Color _getUserColor(String userId) {
    // Generate a color from user ID hash
    final hash = userId.hashCode;
    return Color.fromRGBO(
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      (hash & 0x0000FF),
      1.0,
    );
  }

  @override
  void dispose() {
    print('MultiplayerCursors disposing for board ${widget.boardId}');
    final cursorService = ref.read(cursorServiceProvider);
    cursorService.unsubscribe();
    super.dispose();
  }

  @override
  void deactivate() {
    print('MultiplayerCursors deactivating for board ${widget.boardId}');
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onPointerHover,
      child: Stack(
        children: [
          widget.child,
          // Render other users' cursors
          ..._cursors.values.map((cursor) => _CursorWidget(cursor: cursor)),
        ],
      ),
    );
  }
}

class _CursorWidget extends StatelessWidget {
  final CursorPosition cursor;

  const _CursorWidget({required this.cursor});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: cursor.x,
      top: cursor.y,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cursor icon
            Icon(Icons.arrow_upward, color: cursor.color, size: 20),
            // User name label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cursor.color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cursor.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
