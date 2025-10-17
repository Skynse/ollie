import 'package:flutter/material.dart';
import '../models/card.dart' as model;
import '../models/priority.dart';

/// A kanban card component displaying task information
class KanbanCard extends StatelessWidget {
  final model.Card card;

  const KanbanCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to card details
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card title
              Text(
                card.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Card description (if exists)
              if (card.description != null && card.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  card.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 8),

              // Card metadata (labels, assignees, due date, etc.)
              _buildMetadata(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        // Priority indicator
        if (card.priority != Priority.low) _buildPriorityChip(),

        // Due date
        if (card.dueDate != null) _buildDueDateChip(),

        // Comment count
        if (card.commentCount > 0) _buildCommentCount(),

        // Assignees
        if (card.assigneeIds.isNotEmpty) _buildAssignees(),
      ],
    );
  }

  Widget _buildPriorityChip() {
    final priorityColor = _getPriorityColor(card.priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: priorityColor),
          const SizedBox(width: 4),
          Text(
            card.priority.toString().split('.').last.toUpperCase(),
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
    final isOverdue = card.dueDate!.isBefore(DateTime.now());
    final color = isOverdue ? Colors.red : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            _formatDueDate(card.dueDate!),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCount() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chat_bubble_outline, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '${card.commentCount}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignees() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: card.assigneeIds.take(2).map((assigneeId) {
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: CircleAvatar(
            radius: 10,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              'U',
              style: TextStyle(
                fontSize: 8,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
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
    if (difference < 0) return '${-difference}d ago';
    return '${difference}d';
  }
}
