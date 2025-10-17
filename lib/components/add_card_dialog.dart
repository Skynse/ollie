import 'package:flutter/material.dart';
import '../models/priority.dart';
import 'ollie_ui/ollie_dialog.dart';
import 'ollie_ui/ollie_textfield.dart';
import 'ollie_ui/ollie_button.dart';
import 'ollie_ui/ollie_toast.dart';

/// Dialog for creating a new card
class AddCardDialog extends StatefulWidget {
  final Future<bool> Function({
    required String title,
    String? description,
    required Priority priority,
  })
  onCreateCard;

  const AddCardDialog({super.key, required this.onCreateCard});

  @override
  State<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends State<AddCardDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;
  Priority _selectedPriority = Priority.low;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_titleController.text.trim().isEmpty) {
      OllieToast.info(context, 'Please enter a card title');
      return;
    }

    setState(() => _isCreating = true);

    final success = await widget.onCreateCard(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
    );

    if (mounted) {
      setState(() => _isCreating = false);
      if (success) {
        Navigator.pop(context);
        OllieToast.success(context, 'Card created!');
      } else {
        OllieToast.error(context, 'Failed to create card');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OllieDialog(
      title: 'Add Card',
      width: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title input
          OllieTextfield.simple(
            label: 'Card Title',
            hint: 'e.g., Fix login bug',
            controller: _titleController,
            enabled: !_isCreating,
          ),

          const SizedBox(height: 20),

          // Card description input
          OllieTextfield.simple(
            label: 'Description (optional)',
            hint: 'Add more details...',
            controller: _descriptionController,
            enabled: !_isCreating,
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          // Priority selector
          Text(
            'Priority',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: Priority.values.map((priority) {
              final isSelected = _selectedPriority == priority;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: _isCreating
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() => _selectedPriority = priority);
                          }
                        },
                  selectedColor: _getPriorityColor(priority),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(
                    color: isSelected
                        ? _getPriorityColor(priority)
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
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
          text: 'Create Card',
          onPressed: _handleCreate,
          loading: _isCreating,
          width: null,
        ),
      ],
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
}
