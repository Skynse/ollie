import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card.dart' as model;
import '../providers/sprint_provider.dart';
import '../providers/user_provider.dart';
import 'manual_time_log_dialog.dart';
import 'ollie_ui/ollie_toast.dart';
import 'enhanced_manual_time_log_dialog.dart';
import 'ollie_ui/theme_extensions.dart';

/// Widget for displaying and controlling time tracking on a card
class CardTimerWidget extends ConsumerStatefulWidget {
  final model.Card card;

  const CardTimerWidget({super.key, required this.card});

  @override
  ConsumerState<CardTimerWidget> createState() => _CardTimerWidgetState();
}

class _CardTimerWidgetState extends ConsumerState<CardTimerWidget> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  String _formatHours(double hours) {
    if (hours == 0) return '0h';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final localTimer = ref.watch(localTimerProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) return const SizedBox.shrink();

        // Check if local timer is running on this card
        final isActiveOnThisCard =
            localTimer?.cardId == widget.card.id &&
            localTimer?.userId == currentUser.id;

        // Start local timer if this card has active time log
        if (isActiveOnThisCard && _timer == null && localTimer != null) {
          final elapsed = DateTime.now()
              .difference(localTimer.startTime)
              .inSeconds;
          _elapsedSeconds = elapsed;
          _startTimer();
        } else if (!isActiveOnThisCard && _timer != null) {
          _stopTimer();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActiveOnThisCard
                ? Colors.green.shade50
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActiveOnThisCard
                  ? Colors.green.shade200
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Time display
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: isActiveOnThisCard
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              if (isActiveOnThisCard)
                Text(
                  _formatDuration(_elapsedSeconds),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatHours(widget.card.totalLoggedHours),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (widget.card.estimatedHours != null)
                      Text(
                        ' / ${_formatHours(widget.card.estimatedHours!)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              const SizedBox(width: 8),

              // Divider
              Container(
                width: 1,
                height: 20,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              const SizedBox(width: 8),

              // Timer control button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    if (isActiveOnThisCard && localTimer != null) {
                      // Stop timer - commit to database
                      final duration = DateTime.now()
                          .difference(localTimer.startTime)
                          .inMinutes;

                      // Log the time to database
                      await ref
                          .read(
                            sprintNotifierProvider(
                              widget.card.sprintId ?? '',
                            ).notifier,
                          )
                          .logManualTime(
                            cardId: widget.card.id,
                            userId: currentUser.id,
                            durationMinutes: duration,
                            sprintId: widget.card.sprintId,
                            startTime: localTimer.startTime,
                            endTime: DateTime.now(),
                          );

                      // Clear local timer
                      ref.read(localTimerProvider.notifier).state = null;

                      // Invalidate card data to refresh totalLoggedHours
                      // (You'll need to add this provider invalidation based on your setup)
                    } else if (localTimer != null) {
                      // There's an active timer on another card
                      OllieToast.info(
                        context,
                        'Please stop the active timer first',
                      );
                    } else {
                      // Start timer - only local state, no DB write
                      ref
                          .read(localTimerProvider.notifier)
                          .state = LocalTimerState(
                        cardId: widget.card.id,
                        userId: currentUser.id,
                        sprintId: widget.card.sprintId,
                        startTime: DateTime.now(),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isActiveOnThisCard
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isActiveOnThisCard ? Icons.stop : Icons.play_arrow,
                      size: 18,
                      color: isActiveOnThisCard
                          ? Colors.red.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Manual time entry button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => EnhancedManualTimeLogDialog(
                        cardId: widget.card.id,
                        userId: currentUser.id,
                        sprintId: widget.card.sprintId,
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
              if (widget.card.totalLoggedHours > 0) ...[
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
                            'This will permanently delete all ${_formatHours(widget.card.totalLoggedHours)} of logged time for this card.',
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
                              .getTimeLogsByCard(widget.card.id);

                          // Delete each time log
                          for (final log in timeLogs) {
                            await ref
                                .read(sprintRepositoryProvider)
                                .deleteTimeLog(log.id);
                          }

                          // Refresh the sprint data if card is in a sprint
                          if (widget.card.sprintId != null) {
                            ref.invalidate(
                              sprintNotifierProvider(widget.card.sprintId!),
                            );
                          }

                          if (context.mounted) {
                            OllieToast.success(
                              context,
                              'All time logs cleared',
                            );
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
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
