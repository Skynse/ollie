import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprint.dart';
import '../providers/burndown_provider.dart';
import '../providers/sprint_provider.dart';
import '../utils/responsive.dart';
import 'burndown_chart.dart';
import 'burndown_editor_dialog.dart';

class SprintDetailsDialog extends ConsumerStatefulWidget {
  final String sprintId;

  const SprintDetailsDialog({super.key, required this.sprintId});

  @override
  ConsumerState<SprintDetailsDialog> createState() =>
      _SprintDetailsDialogState();
}

class _SprintDetailsDialogState extends ConsumerState<SprintDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    final sprintAsync = ref.watch(sprintProvider(widget.sprintId));
    final burndownAsync = ref.watch(sprintBurndownProvider(widget.sprintId));
    final statsAsync = ref.watch(sprintBurndownStatsProvider(widget.sprintId));

    final isMobile = context.isMobile;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Container(
        width: isMobile ? double.infinity : 800,
        constraints: BoxConstraints(
          maxHeight: isMobile ? context.height * 0.9 : 700,
        ),
        child: sprintAsync.when(
          data: (sprint) =>
              _buildDialog(context, sprint, burndownAsync, statsAsync),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load sprint: ${error.toString()}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(
    BuildContext context,
    Sprint sprint,
    AsyncValue<List<BurndownDataPoint>> burndownAsync,
    AsyncValue<BurndownStats> statsAsync,
  ) {
    return Column(
      children: [
        // Header
        _buildHeader(context, sprint),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sprint info
                _buildSprintInfo(sprint),
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

                // Burndown chart header with edit button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Burndown Chart',
                      style: TextStyle(
                        fontSize: 13,
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

                        if (result == true) {
                          ref.invalidate(
                            sprintBurndownComputedProvider(widget.sprintId),
                          );
                          // Refresh burndown data
                          ref.invalidate(
                            sprintBurndownProvider(widget.sprintId),
                          );
                          ref.invalidate(
                            sprintBurndownStatsProvider(widget.sprintId),
                          );
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text(
                        'Edit Data',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Burndown chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: burndownAsync.when(
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Sprint sprint) {
    String statusText;
    Color statusColor;

    switch (sprint.status) {
      case SprintStatus.active:
        statusText = 'Active';
        statusColor = const Color(0xff10b981);
        break;
      case SprintStatus.completed:
        statusText = 'Completed';
        statusColor = const Color(0xff6b7280);
        break;
      case SprintStatus.planning:
        statusText = 'Planning';
        statusColor = const Color(0xff3b82f6);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sprint.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (sprint.goal != null && sprint.goal!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sprint.goal!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
            tooltip: 'Close',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSprintInfo(Sprint sprint) {
    final startStr =
        '${sprint.startDate.month}/${sprint.startDate.day}/${sprint.startDate.year}';
    final endStr =
        '${sprint.endDate.month}/${sprint.endDate.day}/${sprint.endDate.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sprint Information',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Duration',
                  value: '$startStr - $endStr',
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.schedule_outlined,
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
                  icon: Icons.style_outlined,
                  label: 'Cards',
                  value: '${sprint.cardIds.length} cards',
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.flag_outlined,
                  label: 'Target Hours',
                  value: '${sprint.targetHours.toStringAsFixed(1)}h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BurndownStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = context.isMobile;

        final cards = [
          _StatsCard(
            title: 'Logged Hours',
            value: stats.loggedHours.toStringAsFixed(1),
            subtitle: 'of ${stats.targetHours.toStringAsFixed(1)}h target',
            icon: Icons.access_time,
            color: Colors.blue,
            progress: stats.percentComplete / 100,
          ),
          _StatsCard(
            title: 'Remaining',
            value: stats.remainingHours.toStringAsFixed(1),
            subtitle: '${stats.daysRemaining} days left',
            icon: Icons.hourglass_bottom,
            color: Colors.orange,
          ),
          _StatsCard(
            title: 'Progress',
            value: '${stats.percentComplete.toInt()}%',
            subtitle: stats.isOnTrack ? 'On track' : 'Behind schedule',
            icon: stats.isOnTrack ? Icons.trending_up : Icons.warning,
            color: stats.isOnTrack ? Colors.green : Colors.red,
          ),
        ];

        if (isMobile) {
          // Mobile: Stack vertically
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        // Desktop: Row layout
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
