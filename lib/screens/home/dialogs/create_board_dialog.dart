import 'package:flutter/material.dart';
import 'package:ollie/components/ollie_ui/ollie_dialog.dart';
import 'package:ollie/components/ollie_ui/ollie_textfield.dart';
import 'package:ollie/components/ollie_ui/ollie_button.dart';
import 'package:ollie/components/ollie_ui/ollie_toast.dart';

/// Create board dialog - only triggers API call on button click
class CreateBoardDialog extends StatefulWidget {
  final Future<bool> Function(String name, String? description) onCreateBoard;

  const CreateBoardDialog({super.key, required this.onCreateBoard});

  @override
  State<CreateBoardDialog> createState() => _CreateBoardDialogState();
}

class _CreateBoardDialogState extends State<CreateBoardDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_nameController.text.trim().isEmpty) {
      OllieToast.info(context, 'Please enter a board name');
      return;
    }

    setState(() => _isCreating = true);

    final success = await widget.onCreateBoard(
      _nameController.text.trim(),
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    if (mounted) {
      setState(() => _isCreating = false);
      if (success) {
        Navigator.pop(context);
        OllieToast.success(context, 'Board created!');
      } else {
        OllieToast.error(context, 'Failed to create board');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OllieDialog(
      title: 'Create Board',
      width: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Board name input
          OllieTextfield.simple(
            label: 'Board Name',
            hint: 'e.g., Sprint Planning',
            controller: _nameController,
            enabled: !_isCreating,
          ),

          const SizedBox(height: 20),

          // Description input
          OllieTextfield.simple(
            label: 'Description (optional)',
            hint: 'What will you track in this board?',
            controller: _descriptionController,
            enabled: !_isCreating,
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        // Cancel button
        OllieButton.text(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
          disabled: _isCreating,
          width: null,
        ),

        // Create button
        OllieButton(
          text: 'Create Board',
          onPressed: _handleCreate,
          loading: _isCreating,
          width: null,
        ),
      ],
    );
  }
}
