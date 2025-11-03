import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/board_provider.dart';
import 'ollie_ui/ollie_toast.dart';
import 'ollie_ui/theme_extensions.dart';

class ManageMembersDialog extends ConsumerStatefulWidget {
  final String boardId;
  final Future<void> Function(String userId) onRemoveMember;
  final VoidCallback onInviteMore;

  const ManageMembersDialog({
    super.key,
    required this.boardId,
    required this.onRemoveMember,
    required this.onInviteMore,
  });

  @override
  ConsumerState<ManageMembersDialog> createState() =>
      _ManageMembersDialogState();
}

class _ManageMembersDialogState extends ConsumerState<ManageMembersDialog> {
  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(boardNotifierProvider(widget.boardId));

    return boardAsync.when(
      data: (boardState) => _buildDialog(
        context,
        boardState.board.memberIds,
        boardState.board.createdBy,
      ),
      loading: () => Dialog(
        child: Container(
          width: 600,
          height: 400,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Dialog(
        child: Container(
          width: 600,
          height: 400,
          alignment: Alignment.center,
          child: Text(
            'Failed to load board: ${error.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(
    BuildContext context,
    List<String> memberIds,
    String createdBy,
  ) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: context.borderColor)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: context.primaryColor),
                  const SizedBox(width: 12),
                  const Text(
                    'Manage Members',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Member list
            Expanded(
              child: memberIds.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: memberIds.length,
                      itemBuilder: (context, index) {
                        final memberId = memberIds[index];
                        final isOwner = memberId == createdBy;
                        return _MemberTile(
                          key: ValueKey(memberId),
                          memberId: memberId,
                          isOwner: isOwner,
                          onRemove: isOwner
                              ? null
                              : () => _confirmRemoveMember(
                                  context,
                                  memberId,
                                  ref,
                                ),
                        );
                      },
                    ),
            ),

            // Footer with invite button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onInviteMore();
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Members'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: context.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No members yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite people to collaborate on this board',
            style: TextStyle(color: context.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    String memberId,
    WidgetRef ref,
  ) async {
    final userAsync = ref.read(userProvider(memberId));
    String userName = 'this member';
    userAsync.whenData((user) => userName = user.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove $userName from this board?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await widget.onRemoveMember(memberId);
        if (context.mounted) {
          OllieToast.success(context, 'Member removed successfully');
        }
      } catch (e) {
        if (context.mounted) {
          OllieToast.error(context, 'Failed to remove member: ${e.toString()}');
        }
      }
    }
  }
}

class _MemberTile extends ConsumerWidget {
  final String memberId;
  final bool isOwner;
  final VoidCallback? onRemove;

  const _MemberTile({
    super.key,
    required this.memberId,
    required this.isOwner,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(memberId));

    return userAsync.when(
      data: (user) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: context.primaryColor.withOpacity(0.2),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: context.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (isOwner) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Owner',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(user.email),
          trailing: isOwner
              ? Tooltip(
                  message: 'Board owner cannot be removed',
                  child: Icon(Icons.lock, color: context.disabledColor),
                )
              : IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.remove_circle, color: context.dangerColor),
                  tooltip: 'Remove member',
                ),
        ),
      ),
      loading: () => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: context.borderColor),
          title: Container(height: 16, width: 100, color: context.borderColor),
          subtitle: Container(
            height: 12,
            width: 150,
            color: context.borderColor,
          ),
        ),
      ),
      error: (error, _) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: context.dangerColor.withOpacity(0.2),
            child: Icon(Icons.error, color: context.dangerColor),
          ),
          title: const Text('Failed to load user'),
          subtitle: Text(error.toString()),
        ),
      ),
    );
  }
}
