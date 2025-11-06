import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/ollie_ui/ollie_context_menu.dart';
import 'package:ollie/providers/board_provider.dart';
import '../models/card.dart' as model;
import '../models/sprint.dart';
import '../providers/sprint_provider.dart';
import 'assign_member_dialog.dart';
import 'edit_card_dialog.dart';
import 'enhanced_card_content.dart';
import 'ollie_ui/ollie_toast.dart';
import 'ollie_ui/theme_extensions.dart';

/// A kanban card component displaying task information
class KanbanCard extends ConsumerStatefulWidget {
  final model.Card card;
  final String boardId;

  const KanbanCard({super.key, required this.card, required this.boardId});

  @override
  ConsumerState<KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends ConsumerState<KanbanCard> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return OllieContextMenu(
      items: [
        OllieMenuItem(
          title: 'Edit Card',
          icon: Icons.edit_outlined,
          onTap: () {
            // Using Future.delayed is good practice to show the dialog after the menu closes.
            Future.delayed(Duration.zero, () {
              showDialog(
                context: context,
                builder: (context) =>
                    EditCardDialog(card: widget.card, boardId: widget.boardId),
              );
            });
          },
        ),
        // toggle complete, ? depending on if completed or not string changes
        OllieMenuItem(
          title: widget.card.completed ? 'Mark Incomplete' : 'Mark Complete',
          icon: widget.card.completed
              ? Icons.check_box_outline_blank
              : Icons.check_box,
          onTap: () async {
            final updatedCard = widget.card.copyWith(
              completed: !widget.card.completed,
            );
            await ref
                .read(boardNotifierProvider(widget.boardId).notifier)
                .updateCard(updatedCard: updatedCard);
          },
        ),
        OllieMenuItem(
          title: 'Change Members',
          icon: Icons.group_outlined,
          onTap: () {
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
        OllieMenuItem(
          title: 'Add to Sprint',
          icon: Icons.timer_outlined,
          onTap: () {
            Future.delayed(Duration.zero, () {
              _showAddToSprintDialog(context, ref);
            });
          },
        ),
        OllieMenuItem(
          title: 'Delete Card',
          icon: Icons.delete_outline_rounded,
          onTap: () async {
            final boardNotifier = ref.read(
              boardNotifierProvider(widget.boardId).notifier,
            );
            await boardNotifier.deleteCard(widget.card.id);
          },
        ),
      ],
      child: Draggable<model.Card>(
        data: widget.card,
        onDragStarted: () {
          setState(() => _isDragging = true);
        },
        onDragEnd: (_) {
          // Reset drag state after a short delay to prevent tap from firing
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() => _isDragging = false);
            }
          });
        },
        feedback: Transform.rotate(
          angle: 0.05, // ~3 degrees tilt
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 280, child: _buildCardContent(context, ref)),
          ),
        ),
        childWhenDragging:
            const SizedBox.shrink(), // Hide original card when dragging
        child: _buildCardContent(context, ref),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref) {
    return EnhancedCardContent(
      card: widget.card,
      onTap: () {
        if (!_isDragging) {
          showDialog(
            context: context,
            builder: (context) =>
                EditCardDialog(card: widget.card, boardId: widget.boardId),
          );
        }
      },
    );
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
                        ? context.successColor
                        : context.secondaryTextColor,
                  ),
                  title: Text(sprint.name),
                  subtitle: Text(
                    '${sprint.status.toString().split('.').last} - ${sprint.cardIds.length} cards',
                  ),
                  trailing: isInSprint
                      ? Icon(Icons.check, color: context.successColor)
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
