import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprint.dart';
import '../providers/sprint_provider.dart';
import 'edit_sprint_dialog.dart';
import 'sprint_details_dialog.dart';
import 'ollie_ui/ollie_toast.dart';
import 'ollie_ui/theme_extensions.dart';

class SprintManagementDialog extends ConsumerStatefulWidget {
  final String boardId;

  const SprintManagementDialog({super.key, required this.boardId});

  @override
  ConsumerState<SprintManagementDialog> createState() =>
      _SprintManagementDialogState();
}

class _SprintManagementDialogState
    extends ConsumerState<SprintManagementDialog> {
  @override
  Widget build(BuildContext context) {
    final sprintsAsync = ref.watch(boardSprintsProvider(widget.boardId));
    final activeSprint = ref.watch(sprintNotifierProvider(widget.boardId));

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Sprint list
            Flexible(
              child: sprintsAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Error loading sprints: $error',
                      style: TextStyle(color: context.dangerColor),
                    ),
                  ),
                ),
                data: (sprints) {
                  if (sprints.isEmpty) return _buildEmptyState();
                  return _buildSprintList(sprints, activeSprint);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.bolt_rounded, color: context.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sprints',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Close',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSprintList(List<Sprint> sprints, Sprint? activeSprint) {
    final sorted = List<Sprint>.from(sprints)
      ..sort((a, b) {
        if (a.status == SprintStatus.active) return -1;
        if (b.status == SprintStatus.active) return 1;
        if (a.status == SprintStatus.planning &&
            b.status == SprintStatus.completed) { return -1; }
        if (b.status == SprintStatus.planning &&
            a.status == SprintStatus.completed) { return 1; }
        return b.startDate.compareTo(a.startDate);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final sprint = sorted[index];
        return _SprintTile(
          key: ValueKey(sprint.id),
          sprint: sprint,
          isActiveSprint: sprint.id == activeSprint?.id,
          onStart: sprint.status == SprintStatus.planning
              ? () => _confirmStart(sprint)
              : null,
          onComplete: sprint.status == SprintStatus.active
              ? () => _confirmComplete(sprint)
              : null,
          onEdit: sprint.status != SprintStatus.completed
              ? () => _openEditDialog(sprint)
              : null,
          onDelete: sprint.status != SprintStatus.active
              ? () => _confirmDelete(sprint)
              : null,
          onViewDetails: sprint.status != SprintStatus.planning
              ? () => _showDetails(sprint)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt_outlined, size: 44, color: context.secondaryTextColor),
            const SizedBox(height: 12),
            Text(
              'No sprints yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a sprint to start planning your work',
              style: TextStyle(fontSize: 13, color: context.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStart(Sprint sprint) async {
    final confirmed = await _showConfirmDialog(
      title: 'Start Sprint',
      message:
          'Start "${sprint.name}"?\n\nDuration: ${sprint.durationDays} day(s)  ·  Cards: ${sprint.cardIds.length}',
      confirmLabel: 'Start Sprint',
      confirmColor: Colors.green,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(sprintNotifierProvider(widget.boardId).notifier)
          .startSprint(sprint.id);
      if (mounted) OllieToast.success(context, 'Sprint started');
    } catch (e) {
      if (mounted) OllieToast.error(context, 'Failed to start sprint: $e');
    }
  }

  Future<void> _confirmComplete(Sprint sprint) async {
    final confirmed = await _showConfirmDialog(
      title: 'Complete Sprint',
      message:
          'Complete "${sprint.name}"?\n\nThis will mark the sprint as finished.',
      confirmLabel: 'Complete Sprint',
      confirmColor: Colors.blue,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(sprintNotifierProvider(widget.boardId).notifier)
          .completeSprint(sprint.id);
      if (mounted) OllieToast.success(context, 'Sprint completed');
    } catch (e) {
      if (mounted) OllieToast.error(context, 'Failed to complete sprint: $e');
    }
  }

  Future<void> _confirmDelete(Sprint sprint) async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Sprint',
      message:
          'Delete "${sprint.name}"?\n\nThis action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(sprintNotifierProvider(widget.boardId).notifier)
          .deleteSprint(sprint.id);
      if (mounted) OllieToast.success(context, 'Sprint deleted');
    } catch (e) {
      if (mounted) OllieToast.error(context, 'Failed to delete sprint: $e');
    }
  }

  void _openEditDialog(Sprint sprint) {
    showDialog(
      context: context,
      builder: (context) =>
          EditSprintDialog(boardId: widget.boardId, sprint: sprint),
    );
  }

  void _showDetails(Sprint sprint) {
    showDialog(
      context: context,
      builder: (context) => SprintDetailsDialog(sprintId: sprint.id),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: confirmColor != null
                ? FilledButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _SprintTile extends StatelessWidget {
  final Sprint sprint;
  final bool isActiveSprint;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  const _SprintTile({
    super.key,
    required this.sprint,
    required this.isActiveSprint,
    this.onStart,
    this.onComplete,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
  });

  Color _statusColor() {
    switch (sprint.status) {
      case SprintStatus.active:
        return const Color(0xff10b981);
      case SprintStatus.completed:
        return const Color(0xff6b7280);
      case SprintStatus.planning:
        return const Color(0xff3b82f6);
    }
  }

  String _statusLabel() {
    switch (sprint.status) {
      case SprintStatus.active:
        return 'Active';
      case SprintStatus.completed:
        return 'Completed';
      case SprintStatus.planning:
        return 'Planning';
    }
  }

  IconData _statusIcon() {
    switch (sprint.status) {
      case SprintStatus.active:
        return Icons.play_circle_filled_rounded;
      case SprintStatus.completed:
        return Icons.check_circle_rounded;
      case SprintStatus.planning:
        return Icons.schedule_rounded;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.month}/${d.day}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final isActive = sprint.status == SprintStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(
          color: isActiveSprint ? color.withValues(alpha: 0.4) : context.borderColor,
          width: isActiveSprint ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Icon(_statusIcon(), color: color, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sprint.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        _statusLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                // Goal
                if (sprint.goal != null && sprint.goal!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    sprint.goal!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.secondaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Meta row
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${_formatDate(sprint.startDate)} – ${_formatDate(sprint.endDate)}',
                    ),
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      label: '${sprint.durationDays}d',
                    ),
                    _MetaChip(
                      icon: Icons.credit_card_rounded,
                      label: '${sprint.cardIds.length} card${sprint.cardIds.length == 1 ? '' : 's'}',
                    ),
                    _MetaChip(
                      icon: Icons.flag_rounded,
                      label: '${sprint.targetHours.toStringAsFixed(sprint.targetHours % 1 == 0 ? 0 : 1)}h target',
                    ),
                  ],
                ),

                // Progress bar for active sprints
                if (isActive) ...[
                  const SizedBox(height: 10),
                  _ProgressBar(
                    progress: sprint.progress.clamp(0.0, 1.0),
                    daysRemaining: sprint.daysRemaining.toInt(),
                    color: color,
                  ),
                ],

                const SizedBox(height: 10),

                // Action row
                Row(
                  children: [
                    if (onViewDetails != null)
                      TextButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(Icons.show_chart_rounded, size: 15),
                        label: const Text('Details', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const Spacer(),

                    // Edit button (planning & active only)
                    if (onEdit != null) ...[
                      _ActionIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit sprint',
                        color: context.primaryColor,
                        onPressed: onEdit!,
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Start button
                    if (onStart != null) ...[
                      _ActionButton(
                        label: 'Start',
                        icon: Icons.play_arrow_rounded,
                        color: const Color(0xff10b981),
                        onPressed: onStart!,
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Complete button
                    if (onComplete != null) ...[
                      _ActionButton(
                        label: 'Complete',
                        icon: Icons.check_rounded,
                        color: const Color(0xff3b82f6),
                        onPressed: onComplete!,
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Delete button (not for active sprints)
                    if (onDelete != null)
                      _ActionIconButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Delete sprint',
                        color: context.dangerColor,
                        onPressed: onDelete!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.secondaryTextColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final int daysRemaining;
  final Color color;

  const _ProgressBar({
    required this.progress,
    required this.daysRemaining,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}% elapsed',
              style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
            ),
            Text(
              daysRemaining > 0
                  ? '$daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining'
                  : 'Sprint ended',
              style: TextStyle(
                fontSize: 11,
                color: daysRemaining > 0
                    ? context.secondaryTextColor
                    : context.dangerColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: context.borderColor,
            color: daysRemaining > 0 ? color : context.dangerColor,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 18),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
