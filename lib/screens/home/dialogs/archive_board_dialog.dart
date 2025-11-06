import 'package:flutter/material.dart';
import 'package:ollie/components/ollie_ui/ollie_dialog.dart';
import 'package:ollie/components/ollie_ui/ollie_button.dart';

/// Archive board confirmation dialog
class ArchiveBoardDialog extends StatelessWidget {
  final String boardName;
  final VoidCallback onConfirm;

  const ArchiveBoardDialog({
    super.key,
    required this.boardName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return OllieDialog(
      title: 'Archive Board?',
      width: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to archive "$boardName"?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'This board will be moved to your archived boards. You can unarchive it later or delete it permanently.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        // Cancel button
        OllieButton.text(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
          width: null,
        ),

        // Archive button
        OllieButton.secondary(
          text: 'Archive',
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          width: null,
        ),
      ],
    );
  }
}
