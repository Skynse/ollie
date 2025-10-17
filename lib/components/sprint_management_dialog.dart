import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprint.dart';
import 'sprint_details_dialog.dart';

class SprintManagementDialog extends ConsumerWidget {
  final List<Sprint> sprints;
  final Sprint? activeSprint;
  final Future<void> Function(String sprintId) onStartSprint;
  final Future<void> Function(String sprintId) onCompleteSprint;
  final Future<void> Function(String sprintId) onDeleteSprint;

  const SprintManagementDialog({
    super.key,
    required this.sprints,
    this.activeSprint,
    required this.onStartSprint,
    required this.onCompleteSprint,
    required this.onDeleteSprint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedSprints = List<Sprint>.from(sprints)
      ..sort((a, b) {
        // Active first, then planning, then completed
        if (a.status == SprintStatus.active) return -1;
        if (b.status == SprintStatus.active) return 1;
        if (a.status == SprintStatus.planning &&
            b.status == SprintStatus.completed) {
          return -1;
        }
        if (b.status == SprintStatus.planning &&
            a.status == SprintStatus.completed) {
          return 1;
        }
        return b.startDate.compareTo(a.startDate);
      });

    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Sprint Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Sprint list
            Expanded(
              child: sprints.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedSprints.length,
                      itemBuilder: (context, index) {
                        final sprint = sortedSprints[index];
                        return _SprintTile(
                          key: ValueKey(sprint.id),
                          sprint: sprint,
                          isActive: sprint.id == activeSprint?.id,
                          onStart: sprint.status == SprintStatus.planning
                              ? () => _confirmStartSprint(context, sprint)
                              : null,
                          onComplete: sprint.status == SprintStatus.active
                              ? () => _confirmCompleteSprint(context, sprint)
                              : null,
                          onDelete: sprint.status != SprintStatus.active
                              ? () => _confirmDeleteSprint(context, sprint)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No sprints yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a sprint to start organizing your work',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmStartSprint(BuildContext context, Sprint sprint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Sprint'),
        content: Text(
          'Start "${sprint.name}"?\n\n'
          'Duration: ${sprint.durationDays} day(s)\n'
          'Cards: ${sprint.cardIds.length}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start Sprint'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await onStartSprint(sprint.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sprint started successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start sprint: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmCompleteSprint(
    BuildContext context,
    Sprint sprint,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Sprint'),
        content: Text(
          'Complete "${sprint.name}"?\n\n'
          'This will end the sprint and mark it as completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete Sprint'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await onCompleteSprint(sprint.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sprint completed successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete sprint: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteSprint(BuildContext context, Sprint sprint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sprint'),
        content: Text(
          'Are you sure you want to delete "${sprint.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await onDeleteSprint(sprint.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sprint deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete sprint: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _SprintTile extends StatelessWidget {
  final Sprint sprint;
  final bool isActive;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const _SprintTile({
    super.key,
    required this.sprint,
    required this.isActive,
    this.onStart,
    this.onComplete,
    this.onDelete,
  });

  Color _getStatusColor() {
    switch (sprint.status) {
      case SprintStatus.active:
        return Colors.green;
      case SprintStatus.completed:
        return Colors.grey;
      case SprintStatus.planning:
        return Colors.blue;
    }
  }

  Color _getStatusTextColor() {
    switch (sprint.status) {
      case SprintStatus.active:
        return Colors.green.shade700;
      case SprintStatus.completed:
        return Colors.grey.shade700;
      case SprintStatus.planning:
        return Colors.blue.shade700;
    }
  }

  IconData _getStatusIcon() {
    switch (sprint.status) {
      case SprintStatus.active:
        return Icons.play_circle;
      case SprintStatus.completed:
        return Icons.check_circle;
      case SprintStatus.planning:
        return Icons.schedule;
    }
  }

  String _getStatusText() {
    switch (sprint.status) {
      case SprintStatus.active:
        return 'Active';
      case SprintStatus.completed:
        return 'Completed';
      case SprintStatus.planning:
        return 'Planning';
    }
  }

  String _getDateRange() {
    final startStr =
        '${sprint.startDate.month}/${sprint.startDate.day}/${sprint.startDate.year}';
    final endStr =
        '${sprint.endDate.month}/${sprint.endDate.day}/${sprint.endDate.year}';
    return '$startStr - $endStr';
  }

  void _showSprintDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SprintDetailsDialog(sprint: sprint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 4 : 1,
      child: Container(
        decoration: isActive
            ? BoxDecoration(
                border: Border.all(color: Colors.green.shade300, width: 2),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getStatusIcon(), color: statusColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sprint.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (sprint.goal != null && sprint.goal!.isNotEmpty) ...[
                Text(
                  sprint.goal!,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getDateRange(),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${sprint.durationDays} day(s)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.style, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${sprint.cardIds.length} card(s)',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // View Details button (shows burndown chart)
                  if (sprint.status != SprintStatus.planning)
                    TextButton.icon(
                      onPressed: () => _showSprintDetails(context),
                      icon: const Icon(Icons.show_chart, size: 18),
                      label: const Text('View Details'),
                    ),
                  const Spacer(),
                  if (onStart != null)
                    FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Start Sprint'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  if (onComplete != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Complete'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete, color: Colors.red.shade400),
                      tooltip: 'Delete sprint',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
