import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sprint_provider.dart';

/// Dialog for manually entering time log entries
class ManualTimeLogDialog extends ConsumerStatefulWidget {
  final String cardId;
  final String userId;
  final String? sprintId;

  const ManualTimeLogDialog({
    super.key,
    required this.cardId,
    required this.userId,
    this.sprintId,
  });

  @override
  ConsumerState<ManualTimeLogDialog> createState() =>
      _ManualTimeLogDialogState();
}

class _ManualTimeLogDialogState extends ConsumerState<ManualTimeLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitTimeLog() async {
    if (!_formKey.currentState!.validate()) return;

    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final totalMinutes = (hours * 60) + minutes;

    if (totalMinutes == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a duration')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(sprintNotifierProvider(widget.sprintId ?? '').notifier)
          .logManualTime(
            cardId: widget.cardId,
            userId: widget.userId,
            durationMinutes: totalMinutes,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            sprintId: widget.sprintId,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time logged successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to log time: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Time'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Duration',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Hours input
                Expanded(
                  child: TextFormField(
                    controller: _hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final hours = int.tryParse(value);
                        if (hours == null || hours < 0) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Minutes input
                Expanded(
                  child: TextFormField(
                    controller: _minutesController,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final minutes = int.tryParse(value);
                        if (minutes == null || minutes < 0 || minutes >= 60) {
                          return 'Invalid';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Notes input
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submitTimeLog,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Log Time'),
        ),
      ],
    );
  }
}
