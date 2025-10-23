import 'package:flutter/material.dart';
import 'ollie_ui/ollie_dialog.dart';
import 'ollie_ui/ollie_textfield.dart';
import 'ollie_ui/ollie_button.dart';
import 'ollie_ui/ollie_toast.dart';
import 'ollie_ui/theme_extensions.dart';

/// Dialog for creating a new kanban column
class AddColumnDialog extends StatefulWidget {
  final Future<bool> Function(String name, int color, int? wipLimit)
  onCreateColumn;

  const AddColumnDialog({super.key, required this.onCreateColumn});

  @override
  State<AddColumnDialog> createState() => _AddColumnDialogState();
}

class _AddColumnDialogState extends State<AddColumnDialog> {
  final _nameController = TextEditingController();
  final _wipLimitController = TextEditingController();
  bool _isCreating = false;
  int _selectedColor = Colors.grey.toARGB32();

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Gray', 'value': 0xFF808080},
    {'name': 'Red', 'value': 0xFFEF4444},
    {'name': 'Orange', 'value': 0xFFF97316},
    {'name': 'Yellow', 'value': 0xFFEAB308},
    {'name': 'Green', 'value': 0xFF22C55E},
    {'name': 'Blue', 'value': 0xFF3B82F6},
    {'name': 'Purple', 'value': 0xFFA855F7},
    {'name': 'Pink', 'value': 0xFFEC4899},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _wipLimitController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_nameController.text.trim().isEmpty) {
      OllieToast.info(context, 'Please enter a column name');
      return;
    }

    setState(() => _isCreating = true);

    final wipLimit = _wipLimitController.text.trim().isEmpty
        ? null
        : int.tryParse(_wipLimitController.text.trim());

    final success = await widget.onCreateColumn(
      _nameController.text.trim(),
      _selectedColor,
      wipLimit,
    );

    if (mounted) {
      setState(() => _isCreating = false);
      if (success) {
        Navigator.pop(context);
        OllieToast.success(context, 'Column created!');
      } else {
        OllieToast.error(context, 'Failed to create column');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OllieDialog(
      title: 'Add Column',
      width: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column name input
          OllieTextfield.simple(
            label: 'Column Name',
            hint: 'e.g., To Do, In Progress, Done',
            controller: _nameController,
            enabled: !_isCreating,
          ),

          const SizedBox(height: 20),

          // Color picker
          Text(
            'Color',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((colorOption) {
              final isSelected = _selectedColor == colorOption['value'];
              return GestureDetector(
                onTap: _isCreating
                    ? null
                    : () =>
                          setState(() => _selectedColor = colorOption['value']),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(colorOption['value']),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? context.primaryColor
                          : context.borderColor,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: context.surfaceColor, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // WIP limit input (optional)
          OllieTextfield.simple(
            label: 'WIP Limit (optional)',
            hint: 'Max cards allowed',
            controller: _wipLimitController,
            enabled: !_isCreating,
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
          text: 'Create Column',
          onPressed: _handleCreate,
          loading: _isCreating,
          width: null,
        ),
      ],
    );
  }
}
