import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprint.dart';
import '../providers/sprint_provider.dart';
import '../providers/burndown_provider.dart';
import 'burndown_chart.dart';
import 'burndown_editor_dialog.dart';
import 'ollie_ui/ollie_dialog.dart';
import 'ollie_ui/ollie_button.dart';
import 'ollie_ui/ollie_toast.dart';

/// Dialog for completing a sprint with burndown review and adjustments
class SprintCompletionDialog extends ConsumerStatefulWidget {
  final Sprint sprint;

  const SprintCompletionDialog({super.key, required this.sprint});

  @override
  ConsumerState<SprintCompletionDialog> createState() =>
      _SprintCompletionDialogState();
}

class _SprintCompletionDialogState
    extends ConsumerState<SprintCompletionDialog> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(sprintBurndownStatsProvider(widget.sprint.id));
    final burndownAsync = ref.watch(sprintBurndownProvider(widget.sprint.id));

    return OllieDialog(
      title: 'Complete Sprint - ${widget.sprint.name}',
      width: 900,
      content: SizedBox(
        height: 650,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sprint summary header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade50,
                      Colors.blue.shade100.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.sprint.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              if (widget.sprint.goal != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.sprint.goal!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.calendar_today,
                          '${_formatDate(widget.sprint.startDate)} - ${_formatDate(widget.sprint.endDate)}',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.schedule,
                          '${widget.sprint.durationDays} days',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics cards
              statsAsync.when(
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sprint Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Target Hours',
                            '${stats.targetHours.toStringAsFixed(1)}h',
                            Icons.flag,
                            Colors.blue,
                            null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Hours Logged',
                            '${stats.loggedHours.toStringAsFixed(1)}h',
                            Icons.access_time,
                            Colors.green,
                            null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Remaining',
                            '${stats.remainingHours.toStringAsFixed(1)}h',
                            Icons.trending_down,
                            stats.remainingHours > 0
                                ? Colors.orange
                                : Colors.green,
                            null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Completion',
                            '${stats.percentComplete.toStringAsFixed(0)}%',
                            Icons.check_circle,
                            stats.percentComplete >= 90
                                ? Colors.green
                                : Colors.orange,
                            stats.isOnTrack ? 'On Track' : 'Behind Schedule',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Burndown chart
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Burndown Chart',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) =>
                                BurndownEditorDialog(sprint: widget.sprint),
                          );

                          if (result == true && mounted) {
                            // Refresh burndown data
                            ref.invalidate(
                              sprintBurndownProvider(widget.sprint.id),
                            );
                            ref.invalidate(
                              sprintBurndownStatsProvider(widget.sprint.id),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Burndown Data'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  burndownAsync.when(
                    data: (dataPoints) {
                      if (dataPoints.isEmpty) {
                        return Container(
                          height: 250,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            'Sprint hasn\'t started yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      }
                      return Container(
                        height: 250,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: BurndownChart(
                          dataPoints: dataPoints,
                          targetHours: widget.sprint.targetHours,
                          startDate: widget.sprint.startDate,
                          endDate: widget.sprint.endDate,
                        ),
                      );
                    },
                    loading: () => Container(
                      height: 250,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                    error: (error, _) => Container(
                      height: 250,
                      alignment: Alignment.center,
                      child: Text('Error loading burndown: $error'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Completion notes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Completing this sprint will mark it as done and remove it from the active sprint list. You can still view historical data and burndown charts.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OllieButton.text(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
          disabled: _isCompleting,
          width: null,
        ),
        OllieButton(
          text: 'Complete Sprint',
          onPressed: _completeSprint,
          loading: _isCompleting,
          width: null,
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String? subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _completeSprint() async {
    setState(() => _isCompleting = true);

    try {
      await ref
          .read(sprintNotifierProvider(widget.sprint.boardId).notifier)
          .completeSprint(widget.sprint.id);

      if (mounted) {
        Navigator.pop(context, true);
        OllieToast.success(context, 'Sprint completed successfully');
      }
    } catch (e) {
      if (mounted) {
        OllieToast.error(context, 'Failed to complete sprint: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
