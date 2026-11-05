import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card.dart' as model;
import '../models/priority.dart';
import 'ollie_ui/theme_extensions.dart';

/// Enhanced card content widget with better visual design
class EnhancedCardContent extends ConsumerStatefulWidget {
  final model.Card card;
  final VoidCallback onTap;

  const EnhancedCardContent({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  ConsumerState<EnhancedCardContent> createState() =>
      _EnhancedCardContentState();
}

class _EnhancedCardContentState extends ConsumerState<EnhancedCardContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(widget.card.priority);
    final isCompleted = widget.card.completed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedOpacity(
        opacity: isCompleted ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: isCompleted
                ? context.surfaceVariantColor
                : context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? priorityColor.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: priorityColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              else
                ...context.shadowSmall,
            ],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Priority left border indicator
                if (widget.card.priority != Priority.low)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            priorityColor,
                            priorityColor.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          bottomLeft: Radius.circular(11),
                        ),
                      ),
                    ),
                  ),

                // Card content
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.card.priority != Priority.low ? 12 : 8,
                    8,
                    8,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card title with priority icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Completed checkbox indicator
                          if (widget.card.completed)
                            Padding(
                              padding: const EdgeInsets.only(right: 6, top: 1),
                              child: Icon(
                                Icons.check_circle,
                                size: 16,
                                color: context.successColor,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              widget.card.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: widget.card.completed
                                    ? context.secondaryTextColor
                                    : context.textColor,
                                height: 1.3,
                                letterSpacing: -0.1,
                                decoration: widget.card.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationThickness: 2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.card.priority == Priority.high &&
                              !widget.card.completed)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.priority_high,
                                size: 14,
                                color: priorityColor,
                              ),
                            ),
                        ],
                      ),

                      // Card description (if exists)
                      if (widget.card.description != null &&
                          widget.card.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.card.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.secondaryTextColor,
                            height: 1.3,
                            decoration: widget.card.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Card metadata
                      _buildMetadata(),
                    ],
                  ),
                ),

                // Quick actions overlay (on hover)
                if (_isHovered)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: context.shadowMedium,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QuickActionButton(
                            icon: Icons.edit,
                            color: context.primaryColor,
                            onTap: widget.onTap,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Priority chip (only for medium/high)
        if (widget.card.priority != Priority.low) _buildPriorityChip(),

        // Due date chip
        if (widget.card.dueDate != null) _buildDueDateChip(),

        // Subtask progress
        if (widget.card.subtaskCount > 0) _buildSubtaskProgress(),
      ],
    );
  }

  Widget _buildPriorityChip() {
    final priorityColor = _getPriorityColor(widget.card.priority);
    final priorityText = widget.card.priority.toString().split('.').last;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 10, color: priorityColor),
          const SizedBox(width: 3),
          Text(
            priorityText[0].toUpperCase() + priorityText.substring(1),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: priorityColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip() {
    final now = DateTime.now();
    final dueDate = widget.card.dueDate!;
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final isOverdue = dueDay.isBefore(today);
    final daysUntilDue = dueDay.difference(today).inDays;
    final isApproaching = daysUntilDue <= 2 && daysUntilDue >= 0;

    Color chipColor;
    Color textColor;
    IconData iconData;

    if (isOverdue) {
      chipColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      iconData = Icons.warning_rounded;
    } else if (isApproaching) {
      chipColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      iconData = Icons.schedule;
    } else {
      chipColor = context.surfaceVariantColor;
      textColor = context.secondaryTextColor;
      iconData = Icons.calendar_today;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isOverdue
              ? Colors.red.shade200
              : isApproaching
              ? Colors.orange.shade200
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            _formatDueDate(dueDate),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskProgress() {
    final total = widget.card.subtaskCount;
    final done = widget.card.completedSubtaskCount;
    final isComplete = done == total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isComplete
            ? context.successColor.withValues(alpha: 0.12)
            : context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_box : Icons.check_box_outline_blank,
            size: 10,
            color: isComplete
                ? context.successColor
                : context.secondaryTextColor,
          ),
          const SizedBox(width: 3),
          Text(
            '$done/$total',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isComplete
                  ? context.successColor
                  : context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Color(0xFFEF4444);
      case Priority.medium:
        return const Color(0xFFF59E0B);
      case Priority.low:
        return Colors.grey;
    }
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < 0) return '${-difference}d overdue';
    if (difference < 7) return 'in ${difference}d';
    return '${date.month}/${date.day}';
  }
}

/// Quick action button for card hover state
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
