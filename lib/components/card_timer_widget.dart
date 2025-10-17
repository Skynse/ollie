import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card.dart' as model;
import '../providers/sprint_provider.dart';
import '../providers/user_provider.dart';
import 'manual_time_log_dialog.dart';

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
    final cardTimeLogsAsync = ref.watch(cardTimeLogsProvider(widget.card.id));

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) return const SizedBox.shrink();

        final activeTimeLogAsync = ref.watch(
          activeTimeLogProvider(currentUser.id),
        );

        return activeTimeLogAsync.when(
          data: (activeTimeLog) {
            final isActiveOnThisCard = activeTimeLog?.cardId == widget.card.id;

            // Calculate total logged hours
            final totalHours = cardTimeLogsAsync.when(
              data: (logs) =>
                  logs.fold<double>(0.0, (sum, log) => sum + log.durationHours),
              loading: () => 0.0,
              error: (_, __) => 0.0,
            );

            // Start local timer if this card has active time log
            if (isActiveOnThisCard && _timer == null && activeTimeLog != null) {
              final elapsed = DateTime.now()
                  .difference(activeTimeLog.startTime)
                  .inSeconds;
              _elapsedSeconds = elapsed;
              _startTimer();
            } else if (!isActiveOnThisCard && _timer != null) {
              _stopTimer();
            }

            final displayHours = totalHours + (_elapsedSeconds / 3600);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActiveOnThisCard
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 10,
                        color: isActiveOnThisCard
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActiveOnThisCard
                            ? _formatDuration(_elapsedSeconds)
                            : _formatHours(displayHours),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActiveOnThisCard
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (widget.card.estimatedHours != null) ...[
                        Text(
                          ' / ${_formatHours(widget.card.estimatedHours!)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Timer control button
                InkWell(
                  onTap: () async {
                    if (isActiveOnThisCard && activeTimeLog != null) {
                      // Stop timer
                      await ref
                          .read(
                            sprintNotifierProvider(
                              widget.card.sprintId ?? '',
                            ).notifier,
                          )
                          .stopTimer(activeTimeLog.id);
                    } else if (activeTimeLog != null) {
                      // There's an active timer on another card
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please stop the active timer first'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      // Start timer
                      await ref
                          .read(
                            sprintNotifierProvider(
                              widget.card.sprintId ?? '',
                            ).notifier,
                          )
                          .startTimer(
                            cardId: widget.card.id,
                            userId: currentUser.id,
                            sprintId: widget.card.sprintId,
                          );
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isActiveOnThisCard ? Icons.stop : Icons.play_arrow,
                      size: 12,
                      color: isActiveOnThisCard
                          ? Colors.red.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ),

                // Manual time entry button
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => ManualTimeLogDialog(
                        cardId: widget.card.id,
                        userId: currentUser.id,
                        sprintId: widget.card.sprintId,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) =>
              const Icon(Icons.error, size: 12, color: Colors.red),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
