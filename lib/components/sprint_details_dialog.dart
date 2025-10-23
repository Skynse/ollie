import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprint.dart';
import '../providers/burndown_provider.dart';
import 'burndown_chart.dart';
import 'burndown_editor_dialog.dart';
import 'ollie_ui/theme_extensions.dart';

class SprintDetailsDialog extends ConsumerWidget {
  final Sprint sprint;

  const SprintDetailsDialog({super.key, required this.sprint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final burndownAsync = ref.watch(sprintBurndownProvider(sprint.id));
    final statsAsync = ref.watch(sprintBurndownStatsProvider(sprint.id));

    return Dialog(
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sprint info
                    _buildSprintInfo(),
                    const SizedBox(height: 24),

                    // Stats summary
                    statsAsync.when(
                      data: (stats) => _buildStatsCards(stats),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text(
                        'Failed to load stats: ${error.toString()}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Burndown chart header with edit button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sprint Burndown Chart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) =>
                                  BurndownEditorDialog(sprint: sprint),
                            );

                            if (result == true) {
                              // Refresh burndown data
                              ref.invalidate(sprintBurndownProvider(sprint.id));
                              ref.invalidate(
                                sprintBurndownStatsProvider(sprint.id),
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

                    // Burndown chart
                    burndownAsync.when(
                      data: (dataPoints) => BurndownChart(
                        dataPoints: dataPoints,
                        targetHours: sprint.targetHours,
                        startDate: sprint.startDate,
                        endDate: sprint.endDate,
                        title: 'Sprint Burndown Chart',
                      ),
                      loading: () => const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Container(
                        height: 300,
                        alignment: Alignment.center,
                        child: Text(
                          'Failed to load burndown data: ${error.toString()}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (sprint.status) {
      case SprintStatus.active:
        statusColor = Colors.green;
        statusIcon = Icons.play_circle;
        break;
      case SprintStatus.completed:
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        break;
      case SprintStatus.planning:
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
    }

    final Color darkColor;
    final Color lightColor;

    switch (sprint.status) {
      case SprintStatus.active:
        darkColor = Colors.green.shade700;
        lightColor = Colors.green.shade500;
        break;
      case SprintStatus.completed:
        darkColor = Colors.grey.shade700;
        lightColor = Colors.grey.shade500;
        break;
      case SprintStatus.planning:
        darkColor = Colors.blue.shade700;
        lightColor = Colors.blue.shade500;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkColor, lightColor],
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sprint.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (sprint.goal != null && sprint.goal!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sprint.goal!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildSprintInfo() {
    final startStr =
        '${sprint.startDate.month}/${sprint.startDate.day}/${sprint.startDate.year}';
    final endStr =
        '${sprint.endDate.month}/${sprint.endDate.day}/${sprint.endDate.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sprint Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.calendar_today,
                    label: 'Duration',
                    value: '$startStr - $endStr',
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.timer,
                    label: 'Days',
                    value: '${sprint.durationDays} days',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.style,
                    label: 'Cards',
                    value: '${sprint.cardIds.length} cards',
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.flag,
                    label: 'Target Hours',
                    value: '${sprint.targetHours.toStringAsFixed(1)}h',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BurndownStats stats) {
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            title: 'Logged Hours',
            value: stats.loggedHours.toStringAsFixed(1),
            subtitle: 'of ${stats.targetHours.toStringAsFixed(1)}h target',
            icon: Icons.access_time,
            color: Colors.blue,
            progress: stats.percentComplete / 100,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatsCard(
            title: 'Remaining',
            value: stats.remainingHours.toStringAsFixed(1),
            subtitle: '${stats.daysRemaining} days left',
            icon: Icons.hourglass_bottom,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatsCard(
            title: 'Progress',
            value: '${stats.percentComplete.toInt()}%',
            subtitle: stats.isOnTrack ? 'On track' : 'Behind schedule',
            icon: stats.isOnTrack ? Icons.trending_up : Icons.warning,
            color: stats.isOnTrack ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? progress;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
