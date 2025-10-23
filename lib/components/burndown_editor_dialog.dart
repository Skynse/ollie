import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprint.dart';
import '../models/burndown_snapshot.dart';
import '../providers/sprint_provider.dart';
import '../providers/burndown_provider.dart';
import 'ollie_ui/ollie_dialog.dart';
import 'ollie_ui/ollie_button.dart';
import 'ollie_ui/ollie_toast.dart';

/// Dialog for editing burndown data at sprint completion
class BurndownEditorDialog extends ConsumerStatefulWidget {
  final Sprint sprint;

  const BurndownEditorDialog({super.key, required this.sprint});

  @override
  ConsumerState<BurndownEditorDialog> createState() =>
      _BurndownEditorDialogState();
}

class _BurndownEditorDialogState extends ConsumerState<BurndownEditorDialog> {
  final List<_EditableBurndownEntry> _entries = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBurndownData();
  }

  Future<void> _loadBurndownData() async {
    final burndownAsync = await ref.read(
      sprintBurndownProvider(widget.sprint.id).future,
    );

    // Convert to editable entries
    setState(() {
      _entries.clear();
      for (var dataPoint in burndownAsync) {
        final actualHours = dataPoint.actualHours ?? dataPoint.remainingHours;
        _entries.add(
          _EditableBurndownEntry(
            date: dataPoint.date,
            remainingHours: dataPoint.remainingHours ?? 0.0,
            actualHours: actualHours,
            controller: TextEditingController(
              text: actualHours.toStringAsFixed(1),
            ),
          ),
        );
      }
    });
  }

  Future<void> _saveSnapshots() async {
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(sprintRepositoryProvider);

      // Create burndown snapshots for each entry
      for (var entry in _entries) {
        final hours =
            double.tryParse(entry.controller.text) ?? entry.actualHours;

        final snapshot = BurndownSnapshot(
          id: '', // Will be generated
          sprintId: widget.sprint.id,
          date: entry.date,
          remainingHours: hours,
          completedHours: widget.sprint.targetHours - hours,
          totalCards: 0, // Could be enhanced to track this
          completedCards: 0,
          scopeChangeHours: 0,
          createdAt: DateTime.now(),
        );

        await repository.createBurndownSnapshot(snapshot);
      }

      if (mounted) {
        Navigator.pop(context, true);
        OllieToast.success(context, 'Burndown data saved');
      }
    } catch (e) {
      if (mounted) {
        OllieToast.error(context, 'Failed to save: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(sprintBurndownStatsProvider(widget.sprint.id));

    return OllieDialog(
      title: 'Edit Burndown - ${widget.sprint.name}',
      width: 800,
      content: SizedBox(
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adjust the actual hours remaining for each day. This is useful for correcting estimates or accounting for scope changes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats summary
            statsAsync.when(
              data: (stats) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade50,
                      Colors.grey.shade100.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    _buildStatItem(
                      'Target',
                      '${stats.targetHours.toStringAsFixed(1)}h',
                      Icons.flag,
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      'Logged',
                      '${stats.loggedHours.toStringAsFixed(1)}h',
                      Icons.access_time,
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      'Remaining',
                      '${stats.remainingHours.toStringAsFixed(1)}h',
                      Icons.trending_down,
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Editable burndown list
            Expanded(
              child: _entries.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        return _buildBurndownEntry(_entries[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        OllieButton.text(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
          disabled: _isSaving,
          width: null,
        ),
        OllieButton(
          text: 'Save Burndown Data',
          onPressed: _saveSnapshots,
          loading: _isSaving,
          width: null,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBurndownEntry(_EditableBurndownEntry entry, int index) {
    final isToday = DateTime.now().difference(entry.date).inDays == 0;
    final isPast = entry.date.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? Colors.blue.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Day number
          Container(
            width: 50,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday ? Colors.blue.shade600 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'D${index}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isToday ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Date
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(entry.date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  isToday ? 'Today' : _getRelativeDate(entry.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Ideal hours (read-only)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ideal',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.remainingHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Actual hours (editable)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actual Remaining',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: entry.controller,
                  enabled: !_isSaving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    suffix: const Text('h'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Variance indicator
          const SizedBox(width: 12),
          Builder(
            builder: (context) {
              final actual =
                  double.tryParse(entry.controller.text) ?? entry.actualHours;
              final variance = actual - entry.remainingHours;

              if (variance.abs() < 0.1) {
                return Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Colors.green.shade600,
                );
              } else if (variance > 0) {
                return Tooltip(
                  message: 'Behind schedule',
                  child: Icon(
                    Icons.trending_up,
                    size: 20,
                    color: Colors.red.shade600,
                  ),
                );
              } else {
                return Tooltip(
                  message: 'Ahead of schedule',
                  child: Icon(
                    Icons.trending_down,
                    size: 20,
                    color: Colors.green.shade600,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekday = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][date.weekday - 1];
    return '$weekday ${date.month}/${date.day}';
  }

  String _getRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1) return '$diff days ago';
    if (diff == -1) return 'Tomorrow';
    return 'In ${-diff} days';
  }

  @override
  void dispose() {
    for (var entry in _entries) {
      entry.controller.dispose();
    }
    super.dispose();
  }
}

class _EditableBurndownEntry {
  final DateTime date;
  final double remainingHours;
  final double actualHours;
  final TextEditingController controller;

  _EditableBurndownEntry({
    required this.date,
    required this.remainingHours,
    required this.actualHours,
    required this.controller,
  });
}
