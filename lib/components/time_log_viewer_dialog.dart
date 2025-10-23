import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_log.dart';
import '../models/card.dart' as model;
import '../providers/sprint_provider.dart';
import '../providers/user_provider.dart';
import 'ollie_ui/ollie_dialog.dart';
import 'ollie_ui/ollie_button.dart';
import 'ollie_ui/ollie_toast.dart';

/// Dialog for viewing and managing time logs for a card
class TimeLogViewerDialog extends ConsumerStatefulWidget {
  final model.Card card;

  const TimeLogViewerDialog({super.key, required this.card});

  @override
  ConsumerState<TimeLogViewerDialog> createState() =>
      _TimeLogViewerDialogState();
}

class _TimeLogViewerDialogState extends ConsumerState<TimeLogViewerDialog> {
  @override
  Widget build(BuildContext context) {
    final timeLogsAsync = ref.watch(cardTimeLogsProvider(widget.card.id));

    return OllieDialog(
      title: 'Time Logs - ${widget.card.title}',
      width: 700,
      content: SizedBox(
        height: 500,
        child: timeLogsAsync.when(
          data: (timeLogs) {
            if (timeLogs.isEmpty) {
              return _buildEmptyState();
            }

            // Sort by most recent first
            final sortedLogs = List<TimeLog>.from(timeLogs)
              ..sort((a, b) => b.startTime.compareTo(a.startTime));

            // Calculate total time
            final totalHours = timeLogs.fold<double>(
              0.0,
              (sum, log) => sum + log.durationHours,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade100.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Logged',
                          _formatHours(totalHours),
                          Icons.access_time,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (widget.card.estimatedHours != null)
                        Expanded(
                          child: _buildStatCard(
                            'Estimated',
                            _formatHours(widget.card.estimatedHours!),
                            Icons.event,
                            Colors.orange,
                          ),
                        ),
                      const SizedBox(width: 16),
                      if (widget.card.estimatedHours != null)
                        Expanded(
                          child: _buildStatCard(
                            'Remaining',
                            _formatHours(
                              (widget.card.estimatedHours! - totalHours).clamp(
                                0,
                                double.infinity,
                              ),
                            ),
                            Icons.trending_down,
                            totalHours > widget.card.estimatedHours!
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Time logs list
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedLogs.length,
                    itemBuilder: (context, index) {
                      return _buildTimeLogItem(sortedLogs[index]);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error loading time logs: $error')),
        ),
      ),
      actions: [
        OllieButton.text(
          text: 'Close',
          onPressed: () => Navigator.pop(context),
          width: null,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLogItem(TimeLog log) {
    final userAsync = ref.watch(userProvider(log.userId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: log.isActive ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: log.isActive ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Time info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      log.isActive ? Icons.play_circle : Icons.check_circle,
                      size: 18,
                      color: log.isActive
                          ? Colors.green.shade600
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.formattedDuration,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (log.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(log.startTime),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatTime(log.startTime)} - ${log.endTime != null ? _formatTime(log.endTime!) : 'ongoing'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            log.notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                userAsync.when(
                  data: (user) => Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Actions
          if (!log.isActive)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: Colors.grey.shade600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'delete') {
                  await _deleteTimeLog(log);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No time logged yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the timer or add time manually',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTimeLog(TimeLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Log'),
        content: Text(
          'Delete ${log.formattedDuration} logged on ${_formatDate(log.startTime)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(sprintRepositoryProvider);
        await repository.deleteTimeLog(log.id);

        // Refresh the time logs
        ref.invalidate(cardTimeLogsProvider(widget.card.id));

        if (mounted) {
          OllieToast.success(context, 'Time log deleted');
        }
      } catch (e) {
        if (mounted) {
          OllieToast.error(context, 'Failed to delete: $e');
        }
      }
    }
  }

  String _formatHours(double hours) {
    if (hours == 0) return '0h';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
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

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
        ? 12
        : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
