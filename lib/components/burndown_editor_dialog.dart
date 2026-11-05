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
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadBurndownData();
  }

  Future<void> _loadBurndownData() async {
    try {
      final points = await ref.read(
        sprintBurndownProvider(widget.sprint.id).future,
      );
      if (!mounted) return;

      for (final entry in _entries) {
        entry.controller.dispose();
      }

      setState(() {
        _isLoadingData = false;
        _entries
          ..clear()
          ..addAll(
            points.map((dataPoint) {
              final actualHours =
                  dataPoint.actualHours ?? dataPoint.remainingHours;
              return _EditableBurndownEntry(
                date: dataPoint.date,
                remainingHours: dataPoint.remainingHours,
                actualHours: actualHours,
                controller: TextEditingController(
                  text: actualHours.toStringAsFixed(1),
                ),
              );
            }),
          );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingData = false);
      OllieToast.error(context, 'Failed to load burndown data: $e');
    }
  }

  Future<void> _saveSnapshots() async {
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(sprintRepositoryProvider);

      // Delete existing snapshots first to avoid duplicates
      final existing = await repository.getBurndownSnapshotsBySprint(
        widget.sprint.id,
      );
      for (final snapshot in existing) {
        await repository.deleteBurndownSnapshot(snapshot.id);
      }

      // Create fresh burndown snapshots for each entry
      for (var entry in _entries) {
        final hours =
            double.tryParse(entry.controller.text) ?? entry.actualHours;

        final snapshot = BurndownSnapshot(
          id: '',
          sprintId: widget.sprint.id,
          date: entry.date,
          remainingHours: hours,
          completedHours: widget.sprint.targetHours - hours,
          totalCards: 0,
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
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adjust the actual hours remaining for each day. This is useful for correcting estimates or accounting for scope changes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                      Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
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
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            // Editable burndown list
            Expanded(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No burndown data available.\nStart logging time against this sprint to generate chart data.',
                        textAlign: TextAlign.center,
                      ),
                    )
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
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBurndownEntry(_EditableBurndownEntry entry, int index) {
    final isToday = DateTime.now().difference(entry.date).inDays == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Day number
          Container(
            width: 50,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'D$index',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isToday
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  isToday ? 'Today' : _getRelativeDate(entry.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.remainingHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
