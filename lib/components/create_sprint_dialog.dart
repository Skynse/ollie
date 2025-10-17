import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/ollie_ui/ollie_dialog.dart';
import 'package:ollie/components/ollie_ui/ollie_textfield.dart';
import '../providers/sprint_provider.dart';
import 'ollie_ui/ollie_toast.dart';

/// Dialog for creating a new sprint
class CreateSprintDialog extends ConsumerStatefulWidget {
  final String boardId;

  const CreateSprintDialog({super.key, required this.boardId});

  @override
  ConsumerState<CreateSprintDialog> createState() => _CreateSprintDialogState();
}

class _CreateSprintDialogState extends ConsumerState<CreateSprintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _targetHoursController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _targetHoursController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = isStartDate
        ? DateTime.now().subtract(const Duration(days: 365))
        : _startDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 14));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createSprint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final targetHours =
          double.tryParse(_targetHoursController.text.trim()) ?? 0;

      await ref
          .read(sprintNotifierProvider(widget.boardId).notifier)
          .createSprint(
            name: _nameController.text.trim(),
            goal: _goalController.text.trim().isEmpty
                ? null
                : _goalController.text.trim(),
            startDate: _startDate,
            endDate: _endDate,
            targetHours: targetHours,
          );

      if (mounted) {
        ref.refresh(sprintNotifierProvider(widget.boardId));
        Navigator.of(context).pop();
        OllieToast.success(context, 'Sprint created successfully');
      }
    } catch (e) {
      if (mounted) {
        OllieToast.error(context, 'Failed to create sprint: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OllieDialog(
      title: 'Create New Sprint',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sprint name
              OllieTextfield.simple(
                controller: _nameController,
                hint: 'e.g., Sprint 1',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a sprint name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sprint goal (optional)
              OllieTextfield.multiline(
                controller: _goalController,
                hint: 'Sprint goal (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Date range
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${_endDate.month}/${_endDate.day}/${_endDate.year}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Target hours
              OllieTextfield.simple(
                controller: _targetHoursController,
                hint: 'Target hours (e.g., 40)',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter target hours';
                  }
                  final hours = double.tryParse(value);
                  if (hours == null || hours <= 0) {
                    return 'Please enter a valid number';
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _createSprint,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
