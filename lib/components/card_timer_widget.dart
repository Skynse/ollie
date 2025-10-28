import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card.dart' as model;
import '../models/time_log.dart';
import '../providers/sprint_provider.dart';
import '../providers/user_provider.dart';
import 'ollie_ui/ollie_toast.dart';
import 'enhanced_manual_time_log_dialog.dart';
import 'ollie_ui/theme_extensions.dart';

/// Widget for displaying logged time on a card (manual time logs only)
class CardTimerWidget extends ConsumerWidget {
  final model.Card card;

  const CardTimerWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) return const SizedBox.shrink();
        return _buildTimeTracking(context, ref, currentUser);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTimeTracking(BuildContext context, WidgetRef ref, currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimeDisplay(context, ref, currentUser),
        const SizedBox(height: 12),
        _buildTimeLogsList(context, ref, currentUser),
      ],
    );
  }

  String _formatHours(double hours) {
    if (hours == 0) return '0h';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Widget _buildTimeLogsList(BuildContext context, WidgetRef ref, currentUser) {
    // Fetch time logs for this card
    return FutureBuilder<List<TimeLog>>(
      future: ref.read(sprintRepositoryProvider).getTimeLogsByCard(card.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Error loading time logs',
            style: TextStyle(color: context.dangerColor),
          );
        }

        final timeLogs = snapshot.data ?? [];

        if (timeLogs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceVariantColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: context.secondaryTextColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'No time logs yet',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: timeLogs.asMap().entries.map((entry) {
              final index = entry.key;
              final log = entry.value;
              final isLast = index == timeLogs.length - 1;

              return _buildTimeLogItem(context, ref, log, isLast);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTimeLogItem(
    BuildContext context,
    WidgetRef ref,
    TimeLog log,
    bool isLast,
  ) {
    final duration = log.endTime?.difference(log.startTime) ?? Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${hours}h ${minutes}m',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Date and notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(log.startTime),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.secondaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: context.secondaryTextColor,
                ),
                onPressed: () => _editTimeLog(context, ref, log),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: context.dangerColor,
                ),
                onPressed: () => _deleteTimeLog(context, ref, log),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _editTimeLog(BuildContext context, WidgetRef ref, TimeLog log) {
    // TODO: Show edit dialog with pre-filled data
    showDialog(
      context: context,
      builder: (context) => EnhancedManualTimeLogDialog(
        cardId: card.id,
        userId: log.userId,
        sprintId: card.sprintId,
        existingLog: log,
      ),
    );
  }

  Future<void> _deleteTimeLog(
    BuildContext context,
    WidgetRef ref,
    TimeLog log,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Log?'),
        content: const Text(
          'This will permanently delete this time log entry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: context.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(sprintRepositoryProvider).deleteTimeLog(log.id);

        if (card.sprintId != null) {
          ref.invalidate(sprintNotifierProvider(card.sprintId!));
        }

        if (context.mounted) {
          OllieToast.success(context, 'Time log deleted');
        }
      } catch (e) {
        if (context.mounted) {
          OllieToast.error(context, 'Failed to delete time log: $e');
        }
      }
    }
  }

  Widget _buildTimeDisplay(BuildContext context, WidgetRef ref, currentUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time display
          Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            _formatHours(card.totalLoggedHours),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (card.estimatedHours != null)
            Text(
              ' / ${_formatHours(card.estimatedHours!)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 8),

          // Divider
          Container(
            width: 1,
            height: 20,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          const SizedBox(width: 8),

          // Manual time entry button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => EnhancedManualTimeLogDialog(
                    cardId: card.id,
                    userId: currentUser.id,
                    sprintId: card.sprintId,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.add,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ),

          // Clear all time logs button (only show if there are logs)
          if (card.totalLoggedHours > 0) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Time Logs?'),
                      content: Text(
                        'This will permanently delete all ${_formatHours(card.totalLoggedHours)} of logged time for this card.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: context.dangerColor,
                          ),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      // Get all time logs for this card
                      final timeLogs = await ref
                          .read(sprintRepositoryProvider)
                          .getTimeLogsByCard(card.id);

                      // Delete each time log
                      for (final log in timeLogs) {
                        await ref
                            .read(sprintRepositoryProvider)
                            .deleteTimeLog(log.id);
                      }

                      // Refresh the sprint data if card is in a sprint
                      if (card.sprintId != null) {
                        ref.invalidate(sprintNotifierProvider(card.sprintId!));
                      }

                      if (context.mounted) {
                        OllieToast.success(context, 'All time logs cleared');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        OllieToast.error(
                          context,
                          'Failed to clear time logs: $e',
                        );
                      }
                    }
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: context.dangerColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
