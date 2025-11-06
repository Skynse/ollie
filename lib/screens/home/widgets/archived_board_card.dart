import 'package:flutter/material.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';
import 'package:ollie/models/board.dart';
import '../utils/time_formatter.dart';

/// Archived board card widget - shows unarchive and delete options
class ArchivedBoardCard extends StatefulWidget {
  final Board board;
  final int index;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  const ArchivedBoardCard({
    super.key,
    required this.board,
    required this.index,
    required this.onUnarchive,
    required this.onDelete,
  });

  @override
  State<ArchivedBoardCard> createState() => _ArchivedBoardCardState();
}

class _ArchivedBoardCardState extends State<ArchivedBoardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? context.borderColor.withOpacity(0.5)
                : context.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.shadowSmall.first.color,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with archive badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceVariantColor.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.archive,
                    size: 20,
                    color: context.secondaryTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.board.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.board.description != null &&
                        widget.board.description!.isNotEmpty)
                      Text(
                        widget.board.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.secondaryTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Text(
                      'Archived ${formatTimeAgo(widget.board.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onUnarchive,
                      icon: const Icon(Icons.unarchive, size: 16),
                      label: const Text('Restore'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: widget.onDelete,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Archived board list item widget
class ArchivedBoardListItem extends StatefulWidget {
  final Board board;
  final int index;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  const ArchivedBoardListItem({
    super.key,
    required this.board,
    required this.index,
    required this.onUnarchive,
    required this.onDelete,
  });

  @override
  State<ArchivedBoardListItem> createState() => _ArchivedBoardListItemState();
}

class _ArchivedBoardListItemState extends State<ArchivedBoardListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? context.borderColor.withOpacity(0.5)
                : context.borderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.archive, size: 24, color: context.secondaryTextColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.board.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Archived ${formatTimeAgo(widget.board.updatedAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: widget.onUnarchive,
                icon: const Icon(Icons.unarchive, size: 16),
                label: const Text('Restore'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                child: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
