import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprint.dart';
import '../models/time_log.dart';
import '../providers/boards_provider.dart';
import '../providers/burndown_provider.dart';
import '../providers/sprint_provider.dart';
import 'burndown_chart.dart';
import 'ollie_ui/ollie_toast.dart';

/// Exports sprint burndown data and raw time logs into a single CSV table.
class SprintBurndownExportDialog extends ConsumerStatefulWidget {
  final Sprint sprint;

  const SprintBurndownExportDialog({super.key, required this.sprint});

  @override
  ConsumerState<SprintBurndownExportDialog> createState() =>
      _SprintBurndownExportDialogState();
}

class _SprintBurndownExportDialogState
    extends ConsumerState<SprintBurndownExportDialog> {
  bool _isGenerating = false;
  String? _csv;

  @override
  void initState() {
    super.initState();
    _generateCsv();
  }

  Future<void> _generateCsv() async {
    setState(() => _isGenerating = true);

    try {
      final timeLogs = await ref.read(
        sprintTimeLogsProvider(widget.sprint.id).future,
      );
      final burndownPoints = await ref.read(
        sprintBurndownProvider(widget.sprint.id).future,
      );
      final cardNames = await _loadCardNames(timeLogs);
      final csv = _buildCsv(
        sprint: widget.sprint,
        timeLogs: timeLogs,
        burndownPoints: burndownPoints,
        cardNames: cardNames,
      );

      if (mounted) {
        setState(() {
          _csv = csv;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        OllieToast.error(context, 'Failed to generate CSV: $e');
      }
    }
  }

  Future<Map<String, String>> _loadCardNames(List<TimeLog> timeLogs) async {
    final boardRepository = ref.read(boardRepositoryProvider);
    final cardNames = <String, String>{};
    final cardIds = timeLogs.map((log) => log.cardId).toSet();

    for (final cardId in cardIds) {
      try {
        final card = await boardRepository.getCard(cardId);
        cardNames[cardId] = card.title;
      } catch (_) {
        cardNames[cardId] = 'Unknown card';
      }
    }

    return cardNames;
  }

  String _buildCsv({
    required Sprint sprint,
    required List<TimeLog> timeLogs,
    required List<BurndownDataPoint> burndownPoints,
    required Map<String, String> cardNames,
  }) {
    final buffer = StringBuffer();
    final exportTime = DateTime.now().toIso8601String();

    buffer.writeln(
      'record_type,exported_at,sprint_id,sprint_name,sprint_status,'
      'sprint_start_date,sprint_end_date,sprint_target_hours,date,'
      'remaining_hours,logged_hours_this_day,cumulative_logged_hours,'
      'time_log_id,card_id,card_name,start_time,end_time,'
      'duration_minutes,duration_hours,is_active,notes',
    );

    final sortedBurndown = [...burndownPoints]
      ..sort((a, b) => a.date.compareTo(b.date));
    var previousRemaining = sprint.targetHours;
    var cumulativeLogged = 0.0;

    for (final point in sortedBurndown) {
      final loggedThisDay = (previousRemaining - point.remainingHours)
          .clamp(0.0, double.infinity)
          .toDouble();
      cumulativeLogged += loggedThisDay;
      previousRemaining = point.remainingHours;

      buffer.writeln(
        '"burndown","$exportTime","${_escapeCsv(sprint.id)}",'
        '"${_escapeCsv(sprint.name)}","${sprint.status.name}",'
        '"${sprint.startDate.toIso8601String()}","${sprint.endDate.toIso8601String()}",'
        '${sprint.targetHours},"${point.date.toIso8601String()}",'
        '${point.remainingHours},$loggedThisDay,$cumulativeLogged,'
        '"","","","","","","","",""',
      );
    }

    final sortedLogs = [...timeLogs]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final log in sortedLogs) {
      final cardName = cardNames[log.cardId] ?? 'Unknown card';
      buffer.writeln(
        '"time_log","$exportTime","${_escapeCsv(sprint.id)}",'
        '"${_escapeCsv(sprint.name)}","${sprint.status.name}",'
        '"${sprint.startDate.toIso8601String()}","${sprint.endDate.toIso8601String()}",'
        '${sprint.targetHours},"","","","",'
        '"${_escapeCsv(log.id)}","${_escapeCsv(log.cardId)}",'
        '"${_escapeCsv(cardName)}",'
        '"${log.startTime.toIso8601String()}","${log.endTime?.toIso8601String() ?? ''}",'
        '${log.durationMinutes},${log.durationHours},${log.isActive},'
        '"${_escapeCsv(log.notes ?? '')}"',
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) => value.replaceAll('"', '""');

  void _copyCsv() {
    if (_csv == null || _csv!.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _csv!));
    OllieToast.success(context, 'Burndown CSV copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Export Burndown CSV',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Includes daily burndown rows and raw sprint time logs with card names.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _isGenerating
                            ? const Center(child: CircularProgressIndicator())
                            : SelectableText(
                                _csv ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _generateCsv,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Regenerate'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isGenerating || _csv == null ? null : _copyCsv,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy CSV'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
