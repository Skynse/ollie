import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import 'ollie_ui/ollie_toast.dart';

class ManageMembersDialog extends ConsumerWidget {
  final String boardId;
  final List<String> memberIds;
  final String createdBy;
  final Future<void> Function(String userId) onRemoveMember;
  final VoidCallback onInviteMore;

  const ManageMembersDialog({
    super.key,
    required this.boardId,
    required this.memberIds,
    required this.createdBy,
    required this.onRemoveMember,
    required this.onInviteMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue.shade700),
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
                      onInviteMore();
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
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No members yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite people to collaborate on this board',
            style: TextStyle(color: Colors.grey.shade600),
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
        await onRemoveMember(memberId);
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
            backgroundColor: Colors.blue.shade100,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.blue.shade700,
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
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    'Owner',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
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
                  child: Icon(Icons.lock, color: Colors.grey.shade400),
                )
              : IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.remove_circle, color: Colors.red.shade400),
                  tooltip: 'Remove member',
                ),
        ),
      ),
      loading: () => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.grey.shade200),
          title: Container(height: 16, width: 100, color: Colors.grey.shade200),
          subtitle: Container(
            height: 12,
            width: 150,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      error: (error, _) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.red.shade100,
            child: Icon(Icons.error, color: Colors.red.shade700),
          ),
          title: const Text('Failed to load user'),
          subtitle: Text(error.toString()),
        ),
      ),
    );
  }
}
