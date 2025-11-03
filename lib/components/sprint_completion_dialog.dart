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
import 'ollie_ui/theme_extensions.dart';

/// Dialog for completing a sprint with burndown review and adjustments
class SprintCompletionDialog extends ConsumerStatefulWidget {
  final String sprintId;

  const SprintCompletionDialog({super.key, required this.sprintId});

  @override
  ConsumerState<SprintCompletionDialog> createState() =>
      _SprintCompletionDialogState();
}

class _SprintCompletionDialogState
    extends ConsumerState<SprintCompletionDialog> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final sprintAsync = ref.watch(sprintProvider(widget.sprintId));
    final statsAsync = ref.watch(sprintBurndownStatsProvider(widget.sprintId));
    final burndownAsync = ref.watch(sprintBurndownProvider(widget.sprintId));

    return sprintAsync.when(
      data: (sprint) =>
          _buildDialog(context, sprint, statsAsync, burndownAsync),
      loading: () => const OllieDialog(
        title: 'Loading Sprint...',
        width: 900,
        content: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => OllieDialog(
        title: 'Error',
        width: 900,
        content: Center(
          child: Text(
            'Failed to load sprint: ${error.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(
    BuildContext context,
    Sprint sprint,
    AsyncValue<BurndownStats> statsAsync,
    AsyncValue<List<BurndownDataPoint>> burndownAsync,
  ) {
    return OllieDialog(
      title: 'Complete Sprint - ${sprint.name}',
      width: 800,
      content: SizedBox(
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sprint summary header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sprint.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              if (sprint.goal != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  sprint.goal!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.calendar_today,
                          '${_formatDate(sprint.startDate)} - ${_formatDate(sprint.endDate)}',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.schedule,
                          '${sprint.durationDays} days',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Statistics cards
              statsAsync.when(
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sprint Statistics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Hours Logged',
                            '${stats.loggedHours.toStringAsFixed(1)}h',
                            Icons.access_time,
                            Colors.green,
                            null,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
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
              const SizedBox(height: 16),

              // Burndown chart
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Burndown Chart',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) =>
                                BurndownEditorDialog(sprint: sprint),
                          );

                          if (result == true && mounted) {
                            // Refresh burndown data
                            ref.invalidate(
                              sprintBurndownProvider(widget.sprintId),
                            );
                            ref.invalidate(
                              sprintBurndownStatsProvider(widget.sprintId),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text(
                          'Edit Data',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  burndownAsync.when(
                    data: (dataPoints) {
                      if (dataPoints.isEmpty) {
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Sprint hasn\'t started yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return Container(
                        height: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: BurndownChart(
                          dataPoints: dataPoints,
                          targetHours: sprint.targetHours,
                          startDate: sprint.startDate,
                          endDate: sprint.endDate,
                        ),
                      );
                    },
                    loading: () => Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                    error: (error, _) => Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Text(
                        'Error loading burndown: $error',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Completion notes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Completing this sprint will mark it as done and remove it from the active sprint list. You can still view historical data and burndown charts.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
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
          onPressed: () => _completeSprint(sprint),
          loading: _isCompleting,
          width: null,
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
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

  Future<void> _completeSprint(Sprint sprint) async {
    setState(() => _isCompleting = true);

    try {
      await ref
          .read(sprintNotifierProvider(sprint.boardId).notifier)
          .completeSprint(sprint.id);

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
