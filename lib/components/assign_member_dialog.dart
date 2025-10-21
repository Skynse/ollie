import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/models/card.dart' as model;
import '../models/user.dart';
import '../providers/board_provider.dart';
import '../providers/user_provider.dart';
import 'ollie_ui/ollie_dialog.dart';
import 'ollie_ui/ollie_button.dart';

/// Dialog for assigning/removing members from a card
class AssignMemberDialog extends ConsumerStatefulWidget {
  final String boardId;
  final model.Card card;
  final List<String> currentAssigneeIds;

  const AssignMemberDialog({
    super.key,
    required this.boardId,
    required this.card,
    required this.currentAssigneeIds,
  });

  @override
  ConsumerState<AssignMemberDialog> createState() => _AssignMemberDialogState();
}

class _AssignMemberDialogState extends ConsumerState<AssignMemberDialog> {
  Set<String> selectedMemberIds = {};

  @override
  void initState() {
    super.initState();
    selectedMemberIds = Set.from(widget.currentAssigneeIds);
  }

  @override
  Widget build(BuildContext context) {
    final boardState = ref.watch(boardNotifierProvider(widget.boardId));

    return boardState.when(
      loading: () => const OllieDialog(
        title: 'Assign Members',
        content: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => OllieDialog(
        title: 'Error',
        content: Text('Failed to load board: $error'),
      ),
      data: (state) {
        final memberIds = state.board.memberIds;
        final membersAsync = ref.watch(usersProvider(memberIds));

        return membersAsync.when(
          loading: () => const OllieDialog(
            title: 'Assign Members',
            content: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => OllieDialog(
            title: 'Error',
            content: Text('Failed to load members: $error'),
          ),
          data: (members) => _buildDialog(context, members),
        );
      },
    );
  }

  Widget _buildDialog(BuildContext context, List<User> members) {
    return OllieDialog(
      title: 'Assign Members',
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select members to assign to this card',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Member list
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isSelected = selectedMemberIds.contains(member.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedMemberIds.add(member.id);
                        } else {
                          selectedMemberIds.remove(member.id);
                        }
                      });
                    },
                    title: Text(member.name),
                    subtitle: Text(member.email),
                    secondary: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OllieButton.outline(
                  text: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                OllieButton(text: 'Save', onPressed: () => _saveAssignments()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAssignments() async {
    final notifier = ref.read(boardNotifierProvider(widget.boardId).notifier);

    // Determine who to add and who to remove
    final toAdd = selectedMemberIds.difference(
      widget.currentAssigneeIds.toSet(),
    );
    final toRemove = widget.currentAssigneeIds.toSet().difference(
      selectedMemberIds,
    );

    // Add new members
    for (final userId in toAdd) {
      widget.card.assigneeIds.add(userId);
    }

    // Remove members
    for (final userId in toRemove) {
      widget.card.assigneeIds.remove(userId);
    }
    await notifier.updateCard(updatedCard: widget.card);
    //

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
