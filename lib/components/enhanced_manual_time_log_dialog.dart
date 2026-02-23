import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_log.dart';
import '../providers/burndown_provider.dart';
import '../providers/sprint_provider.dart';
import 'ollie_ui/ollie_dialog.dart';
import 'ollie_ui/ollie_button.dart';
import 'ollie_ui/ollie_textfield.dart';
import 'ollie_ui/ollie_toast.dart';
import 'ollie_ui/theme_extensions.dart';

/// Enhanced manual time log dialog with date picker and better UX
class EnhancedManualTimeLogDialog extends ConsumerStatefulWidget {
  final String cardId;
  final String boardId;
  final String userId;
  final String? sprintId;
  final TimeLog? existingLog;

  const EnhancedManualTimeLogDialog({
    super.key,
    required this.cardId,
    required this.boardId,
    required this.userId,
    this.sprintId,
    this.existingLog,
  });

  @override
  ConsumerState<EnhancedManualTimeLogDialog> createState() =>
      _EnhancedManualTimeLogDialogState();
}

class _EnhancedManualTimeLogDialogState
    extends ConsumerState<EnhancedManualTimeLogDialog> {
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLogging = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();

    // If editing existing log, populate fields
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      final duration = log.endTime?.difference(log.startTime) ?? Duration.zero;

      _hoursController.text = duration.inHours.toString();
      _minutesController.text = (duration.inMinutes % 60).toString();
      _notesController.text = log.notes ?? '';
      _selectedDate = log.startTime;
      _startTime = TimeOfDay.fromDateTime(log.startTime);
      if (log.endTime != null) {
        _endTime = TimeOfDay.fromDateTime(log.endTime!);
      }
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Auto-calculate duration if end time is set
        if (_endTime != null) {
          _calculateDuration();
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime,
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
        _calculateDuration();
      });
    }
  }

  void _calculateDuration() {
    if (_endTime == null) return;

    final start = Duration(hours: _startTime.hour, minutes: _startTime.minute);
    final end = Duration(hours: _endTime!.hour, minutes: _endTime!.minute);

    var duration = end - start;
    if (duration.isNegative) {
      // Handle overnight work (end time is next day)
      duration = duration + const Duration(days: 1);
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    _hoursController.text = hours.toString();
    _minutesController.text = minutes.toString();
  }

  Future<void> _handleLog() async {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;

    if (hours == 0 && minutes == 0) {
      OllieToast.info(context, 'Please enter time to log');
      return;
    }

    setState(() => _isLogging = true);

    try {
      final totalMinutes = (hours * 60) + minutes;

      // Create start and end times on the selected date
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = _endTime != null
          ? DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _endTime!.hour,
              _endTime!.minute,
            )
          : startDateTime.add(Duration(minutes: totalMinutes));

      if (widget.existingLog != null) {
        // Update existing log
        final updatedLog = widget.existingLog!.copyWith(
          startTime: startDateTime,
          endTime: endDateTime,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        await ref.read(sprintRepositoryProvider).updateTimeLog(updatedLog);
        ref.invalidate(cardTimeLogsProvider(widget.cardId));

        // Refresh sprint data
        ref.invalidate(sprintNotifierProvider(widget.boardId));
        if (widget.sprintId != null && widget.sprintId!.isNotEmpty) {
          ref.invalidate(sprintTimeLogsProvider(widget.sprintId!));
          ref.invalidate(sprintBurndownComputedProvider(widget.sprintId!));
        }

        if (mounted) {
          Navigator.pop(context);
          OllieToast.success(context, 'Time log updated');
        }
      } else {
        // Create new log
        await ref
            .read(sprintNotifierProvider(widget.boardId).notifier)
            .logManualTime(
              cardId: widget.cardId,
              userId: widget.userId,
              durationMinutes: totalMinutes,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              sprintId: widget.sprintId,
              startTime: startDateTime,
              endTime: endDateTime,
            );
        ref.invalidate(cardTimeLogsProvider(widget.cardId));
        if (widget.sprintId != null && widget.sprintId!.isNotEmpty) {
          ref.invalidate(sprintBurndownComputedProvider(widget.sprintId!));
        }

        if (mounted) {
          Navigator.pop(context);
          OllieToast.success(context, 'Time logged: ${hours}h ${minutes}m');
        }
      }
    } catch (e) {
      if (mounted) {
        OllieToast.error(context, 'Failed to log time: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLogging = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().difference(_selectedDate).inDays == 0;

    return OllieDialog(
      title: 'Log Time',
      width: 550,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: context.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isToday ? 'Today' : _formatDate(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Time range selector
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectStartTime,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.surfaceVariantColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: context.secondaryTextColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _startTime.format(context),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'End Time (Optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
                            ),
                          ),
                          if (_endTime != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _endTime = null;
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: context.secondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectEndTime,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.surfaceVariantColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: context.secondaryTextColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _endTime?.format(context) ?? 'Not set',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _endTime != null
                                      ? context.textColor
                                      : context.secondaryTextColor,
                                ),
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
            const SizedBox(height: 20),

            // Duration input
            Text(
              'Duration',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OllieTextfield.simple(
                    label: 'Hours',
                    hint: '0',
                    controller: _hoursController,
                    enabled: !_isLogging,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OllieTextfield.simple(
                    label: 'Minutes',
                    hint: '0',
                    controller: _minutesController,
                    enabled: !_isLogging,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notes
            OllieTextfield.simple(
              label: 'Notes (optional)',
              hint: 'What did you work on?',
              controller: _notesController,
              enabled: !_isLogging,
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        OllieButton.text(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
          disabled: _isLogging,
          width: null,
        ),
        OllieButton(
          text: 'Log Time',
          onPressed: _handleLog,
          loading: _isLogging,
          width: null,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
