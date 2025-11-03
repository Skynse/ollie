import 'package:flutter/material.dart';
import 'package:ollie/models/board_column.dart';
import 'ollie_ui/theme_extensions.dart';

class EditColumnDialog extends StatefulWidget {
  final BoardColumn column;

  const EditColumnDialog({super.key, required this.column});

  @override
  State<EditColumnDialog> createState() => _EditColumnDialogState();
}

class _EditColumnDialogState extends State<EditColumnDialog> {
  late TextEditingController _nameController;
  late TextEditingController _wipLimitController;
  late int _selectedColor;
  final _formKey = GlobalKey<FormState>();

  final List<int> _colorOptions = [
    0xFFF44336, // red
    0xFFFF9800, // orange
    0xFFFFC107, // amber
    0xFF4CAF50, // green
    0xFF009688, // teal
    0xFF2196F3, // blue
    0xFF3F51B5, // indigo
    0xFF9C27B0, // purple
    0xFFE91E63, // pink
    0xFF9E9E9E, // grey
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.column.name);
    _wipLimitController = TextEditingController(
      text: widget.column.wipLimit?.toString() ?? '',
    );
    _selectedColor = widget.column.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wipLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Column'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Column Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Column name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Color',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorOptions.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? context.textColor
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: context.surfaceColor)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wipLimitController,
                decoration: const InputDecoration(
                  labelText: 'WIP Limit (Optional)',
                  hintText: 'Leave empty for no limit',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final num = int.tryParse(value);
                    if (num == null || num <= 0) {
                      return 'Must be a positive number';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'color': _selectedColor,
                'wipLimit': _wipLimitController.text.isEmpty
                    ? null
                    : int.parse(_wipLimitController.text),
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
