import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card.dart' as model;
import '../providers/sprint_provider.dart';
import '../providers/user_provider.dart';
import 'manual_time_log_dialog.dart';
import 'ollie_ui/ollie_toast.dart';

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

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isActiveOnThisCard
                    ? Colors.green.shade50
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActiveOnThisCard
                      ? Colors.green.shade200
                      : Colors.grey.shade200,
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
                  Text(
                    isActiveOnThisCard
                        ? _formatDuration(_elapsedSeconds)
                        : _formatHours(displayHours),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActiveOnThisCard
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                  if (widget.card.estimatedHours != null) ...[
                    Text(
                      ' / ${_formatHours(widget.card.estimatedHours!)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),

                  // Divider
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  const SizedBox(width: 8),

                  // Timer control button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
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
                          OllieToast.info(
                            context,
                            'Please stop the active timer first',
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
                          builder: (context) => ManualTimeLogDialog(
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
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
