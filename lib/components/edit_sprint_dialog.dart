import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/ollie_ui/ollie_dialog.dart';
import 'package:ollie/components/ollie_ui/ollie_textfield.dart';
import '../models/sprint.dart';
import '../providers/sprint_provider.dart';
import 'ollie_ui/ollie_toast.dart';
import 'ollie_ui/theme_extensions.dart';

/// Dialog for editing an existing sprint's details
class EditSprintDialog extends ConsumerStatefulWidget {
  final String boardId;
  final Sprint sprint;

  const EditSprintDialog({
    super.key,
    required this.boardId,
    required this.sprint,
  });

  @override
  ConsumerState<EditSprintDialog> createState() => _EditSprintDialogState();
}

class _EditSprintDialogState extends ConsumerState<EditSprintDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _goalController;
  late final TextEditingController _targetHoursController;

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  bool get _isActive => widget.sprint.status == SprintStatus.active;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sprint.name);
    _goalController = TextEditingController(text: widget.sprint.goal ?? '');
    _targetHoursController = TextEditingController(
      text: widget.sprint.targetHours.toStringAsFixed(
        widget.sprint.targetHours % 1 == 0 ? 0 : 1,
      ),
    );
    _startDate = widget.sprint.startDate;
    _endDate = widget.sprint.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _targetHoursController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    if (isStartDate && _isActive) return; // Can't change start date once active

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

  Future<void> _saveSprint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final targetHours =
          double.tryParse(_targetHoursController.text.trim()) ?? 0;
      final goal = _goalController.text.trim();

      final updated = Sprint(
        id: widget.sprint.id,
        boardId: widget.sprint.boardId,
        name: _nameController.text.trim(),
        goal: goal.isEmpty ? null : goal,
        startDate: _startDate,
        endDate: _endDate,
        targetHours: targetHours,
        status: widget.sprint.status,
        cardIds: widget.sprint.cardIds,
        createdAt: widget.sprint.createdAt,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(sprintNotifierProvider(widget.boardId).notifier)
          .editSprint(updated);

      if (mounted) {
        Navigator.of(context).pop();
        OllieToast.success(context, 'Sprint updated successfully');
      }
    } catch (e) {
      if (mounted) {
        OllieToast.error(context, 'Failed to update sprint: $e');
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
      title: 'Edit Sprint',
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
                            color: context.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _DatePicker(
                          date: _startDate,
                          onTap: _isActive
                              ? null
                              : () => _selectDate(context, true),
                          disabled: _isActive,
                        ),
                        if (_isActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Cannot change while sprint is active',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.secondaryTextColor,
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
                            color: context.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _DatePicker(
                          date: _endDate,
                          onTap: () => _selectDate(context, false),
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
          onPressed: _isLoading ? null : _saveSprint,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onTap;
  final bool disabled;

  const _DatePicker({required this.date, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: disabled
                ? context.borderColor.withValues(alpha: 0.5)
                : context.borderColor,
          ),
          borderRadius: BorderRadius.circular(4),
          color: disabled ? context.surfaceVariantColor : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: disabled ? context.secondaryTextColor : null,
            ),
            const SizedBox(width: 8),
            Text(
              '${date.month}/${date.day}/${date.year}',
              style: TextStyle(
                fontSize: 14,
                color: disabled ? context.secondaryTextColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
