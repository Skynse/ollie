import 'package:flutter/material.dart';
import '../models/card.dart' as model;
import 'ollie_ui/theme_extensions.dart';

/// Enhanced drop zone with better visual feedback
class EnhancedDropZone extends StatefulWidget {
  final List<model.Card> cards;
  final int position;
  final bool isTop;
  final bool isBottom;
  final String columnId;
  final Function(model.Card card, String targetColumnId, int targetPosition)
  onAccept;
  final VoidCallback onDragEnter;
  final VoidCallback onDragLeave;
  final bool forceExpanded;

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
    this.forceExpanded = false,
  });

  @override
  State<EnhancedDropZone> createState() => _EnhancedDropZoneState();
}

class _EnhancedDropZoneState extends State<EnhancedDropZone> {
  @override
  Widget build(BuildContext context) {
    return DragTarget<model.Card>(
      onWillAcceptWithDetails: (details) {
        final draggedCard = details.data;
        // Don't allow dropping in the same position in the same column
        if (draggedCard.columnId == widget.columnId) {
          final originalIndex = widget.cards.indexWhere(
            (c) => c.id == draggedCard.id,
          );
          if (originalIndex == widget.position ||
              originalIndex + 1 == widget.position) {
            return false;
          }
        }
        widget.onDragEnter();
        return true;
      },
      onLeave: (_) => widget.onDragLeave(),
      onAcceptWithDetails: (details) async {
        widget.onDragLeave();
        final draggedCard = details.data;
        await widget.onAccept(draggedCard, widget.columnId, widget.position);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty || widget.forceExpanded;

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
          colors: [
            context.primaryColor.withOpacity(0.1),
            context.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.primaryColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withOpacity(0.2),
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
                color: context.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: context.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drop here',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
              ),
            ),
            Text(
              'Position ${widget.position + 1}',
              style: TextStyle(
                fontSize: 11,
                color: context.primaryColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.isTop || widget.isBottom ? 4 : 8,
    );
  }
}
