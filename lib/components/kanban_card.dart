import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/providers/board_provider.dart';
import '../models/card.dart' as model;
import '../models/priority.dart';
import '../models/sprint.dart';
import '../providers/user_provider.dart';
import '../providers/sprint_provider.dart';
import 'assign_member_dialog.dart';
import 'card_timer_widget.dart';
import 'edit_card_dialog.dart';
import 'ollie_ui/ollie_toast.dart';

/// A kanban card component displaying task information
class KanbanCard extends ConsumerStatefulWidget {
  final model.Card card;
  final String boardId;

  const KanbanCard({super.key, required this.card, required this.boardId});

  @override
  ConsumerState<KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends ConsumerState<KanbanCard>
    with SingleTickerProviderStateMixin {
  bool _isLongPressing = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onLongPressStart() {
    setState(() {
      _isLongPressing = true;
    });
    _scaleController.forward();
  }

  void _onLongPressEnd() {
    setState(() {
      _isLongPressing = false;
    });
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onLongPressStart(),
      onPointerUp: (_) => _onLongPressEnd(),
      onPointerCancel: (_) => _onLongPressEnd(),
      child: LongPressDraggable<model.Card>(
        data: widget.card,
        hapticFeedbackOnStart: true,
        onDragStarted: () {
          _onLongPressEnd();
        },
        onDragEnd: (_) {
          _onLongPressEnd();
        },
        delay: Duration(milliseconds: 100),
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 280,
            child: Opacity(
              opacity: 0.8,
              child: _buildCardContent(context, ref),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildCardContent(context, ref),
        ),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isLongPressing
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ]
                      : [],
                ),
                child: _buildCardContent(context, ref),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref) {
    final boardNotifier = ref.read(
      boardNotifierProvider(widget.boardId).notifier,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) =>
                EditCardDialog(card: widget.card, boardId: widget.boardId),
          );
        },
        onSecondaryTapDown: (details) async {
          showMenu(
            context: context,
            position: RelativeRect.fromRect(
              details.globalPosition & const Size(40, 40),
              Offset.zero & MediaQuery.of(context).size,
            ),
            items: [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit Card'),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    showDialog(
                      context: context,
                      builder: (context) => EditCardDialog(
                        card: widget.card,
                        boardId: widget.boardId,
                      ),
                    );
                  });
                },
              ),
              PopupMenuItem(
                value: 'change_member',
                child: Text('Change Members'),
                onTap: () {
                  // Use Future.delayed to show dialog after menu closes
                  Future.delayed(Duration.zero, () {
                    showDialog(
                      context: context,
                      builder: (context) => AssignMemberDialog(
                        boardId: widget.boardId,
                        card: widget.card,
                        currentAssigneeIds: widget.card.assigneeIds,
                      ),
                    );
                  });
                },
              ),
              PopupMenuItem(
                value: 'add_to_sprint',
                child: Text('Add to Sprint'),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    _showAddToSprintDialog(context, ref);
                  });
                },
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete Card'),
                onTap: () async {
                  await boardNotifier.deleteCard(widget.card.id);
                },
              ),
            ],
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card title
              Text(
                widget.card.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Card description (if exists)
              if (widget.card.description != null &&
                  widget.card.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.card.description!,
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
        // Time tracking
        if (widget.card.sprintId != null) CardTimerWidget(card: widget.card),

        // Priority indicator
        if (widget.card.priority != Priority.low) _buildPriorityChip(),

        // Due date
        if (widget.card.dueDate != null) _buildDueDateChip(),

        // Comment count
        if (widget.card.commentCount > 0) _buildCommentCount(),

        // Assignees
        if (widget.card.assigneeIds.isNotEmpty) _buildAssignees(),
      ],
    );
  }

  Widget _buildPriorityChip() {
    final priorityColor = _getPriorityColor(widget.card.priority);
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
            widget.card.priority.toString().split('.').last.toUpperCase(),
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
    final isOverdue = widget.card.dueDate!.isBefore(DateTime.now());
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
            _formatDueDate(widget.card.dueDate!),
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
          '${widget.card.commentCount}',
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
    return Consumer(
      builder: (context, ref, child) {
        // Take first 3 assignees
        final displayedIds = widget.card.assigneeIds.take(3).toList();
        final remaining = widget.card.assigneeIds.length - displayedIds.length;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...displayedIds.map((assigneeId) {
              final userAsync = ref.watch(userProvider(assigneeId));

              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: userAsync.when(
                  data: (user) => Tooltip(
                    message: user.name,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  loading: () => CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  error: (_, __) => CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red.shade100,
                    child: Icon(Icons.error, size: 10, color: Colors.red),
                  ),
                ),
              );
            }),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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

  void _showAddToSprintDialog(BuildContext context, WidgetRef ref) {
    final sprintsAsync = ref.read(boardSprintsProvider(widget.boardId));

    sprintsAsync.when(
      data: (sprints) {
        // Filter to only show planning and active sprints
        final availableSprints = sprints
            .where((s) => s.status != SprintStatus.completed)
            .toList();

        if (availableSprints.isEmpty) {
          OllieToast.info(context, 'No available sprints. Create one first!');
          return;
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Add to Sprint'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableSprints.map((sprint) {
                final isInSprint = widget.card.sprintId == sprint.id;
                return ListTile(
                  leading: Icon(
                    sprint.status == SprintStatus.active
                        ? Icons.play_circle
                        : Icons.schedule,
                    color: sprint.status == SprintStatus.active
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                  ),
                  title: Text(sprint.name),
                  subtitle: Text(
                    '${sprint.status.toString().split('.').last} - ${sprint.cardIds.length} cards',
                  ),
                  trailing: isInSprint
                      ? Icon(Icons.check, color: Colors.green.shade700)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      // Update card with sprintId
                      var updatedCard = widget.card.copyWith(
                        sprintId: sprint.id,
                      );
                      await ref
                          .read(boardNotifierProvider(widget.boardId).notifier)
                          .updateCard(updatedCard: updatedCard);

                      // Add card to sprint's cardIds list
                      if (!sprint.cardIds.contains(widget.card.id)) {
                        await ref
                            .read(
                              sprintNotifierProvider(widget.boardId).notifier,
                            )
                            .addCardToSprint(sprint.id, widget.card.id);
                      }

                      if (context.mounted) {
                        OllieToast.success(context, 'Added to ${sprint.name}');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        OllieToast.error(
                          context,
                          'Failed to add to sprint: $e',
                        );
                      }
                    }
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
      loading: () {
        OllieToast.info(context, 'Loading sprints...');
      },
      error: (_, __) {
        OllieToast.error(context, 'Failed to load sprints');
      },
    );
  }
}
