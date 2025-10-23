import 'package:flutter/material.dart';
import '../models/card.dart' as model;

/// Enhanced drop zone with better visual feedback
class EnhancedDropZone extends StatelessWidget {
  final List<model.Card> cards;
  final int position;
  final bool isTop;
  final bool isBottom;
  final String columnId;
  final Function(model.Card card, String targetColumnId, int targetPosition)
  onAccept;
  final VoidCallback onDragEnter;
  final VoidCallback onDragLeave;

  const EnhancedDropZone({
    super.key,
    required this.cards,
    required this.position,
    required this.isTop,
    required this.isBottom,
    required this.columnId,
    required this.onAccept,
    required this.onDragEnter,
    required this.onDragLeave,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<model.Card>(
      onWillAcceptWithDetails: (details) {
        final draggedCard = details.data;
        // Don't allow dropping in the same position in the same column
        if (draggedCard.columnId == columnId) {
          final originalIndex = cards.indexWhere((c) => c.id == draggedCard.id);
          if (originalIndex == position || originalIndex + 1 == position) {
            return false;
          }
        }
        onDragEnter();
        return true;
      },
      onLeave: (_) => onDragLeave(),
      onAcceptWithDetails: (details) async {
        onDragLeave();
        final draggedCard = details.data;
        await onAccept(draggedCard, columnId, position);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        if (isHovering) {
          return _buildHoverState();
        } else {
          return _buildEmptyState();
        }
      },
    );
  }

  Widget _buildHoverState() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drop here',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            Text(
              'Position ${position + 1}',
              style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isTop || isBottom ? 4 : 8,
    );
  }
}
