import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprint.dart';
import '../components/burndown_chart.dart';
import 'sprint_provider.dart';

class SprintBurndownComputedData {
  final List<BurndownDataPoint> dataPoints;
  final BurndownStats stats;

  SprintBurndownComputedData({required this.dataPoints, required this.stats});
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

BurndownStats _buildStatsFromProgress({
  required Sprint sprint,
  required double targetHours,
  required double loggedHours,
  required double remainingHours,
}) {
  final percentComplete = targetHours > 0
      ? (loggedHours / targetHours * 100).toDouble()
      : 0.0;

  final now = DateTime.now();
  final sprintDuration = sprint.endDate.difference(sprint.startDate).inDays;
  final daysElapsed = now
      .difference(sprint.startDate)
      .inDays
      .clamp(0, sprintDuration);
  final expectedProgress = sprintDuration > 0
      ? daysElapsed / sprintDuration
      : 0;
  final actualProgress = targetHours > 0 ? loggedHours / targetHours : 0;
  final isOnTrack = actualProgress >= expectedProgress - 0.1;

  return BurndownStats(
    targetHours: targetHours,
    loggedHours: loggedHours,
    remainingHours: remainingHours,
    percentComplete: percentComplete,
    isOnTrack: isOnTrack,
    daysRemaining: sprint.daysRemaining.toInt(),
    cardsCount: sprint.cardIds.length,
  );
}

/// Combined burndown provider to avoid duplicate heavy work for chart + stats.
final sprintBurndownComputedProvider =
    FutureProvider.family<SprintBurndownComputedData, String>((
      ref,
      sprintId,
    ) async {
      final repository = ref.read(sprintRepositoryProvider);
      final sprint = await ref.watch(sprintProvider(sprintId).future);
      final targetHours = sprint.targetHours;

      // Prefer user-edited snapshots when available.
      final snapshots = await repository.getBurndownSnapshotsBySprint(sprintId);
      if (snapshots.isNotEmpty) {
        final sortedSnapshots = [...snapshots]
          ..sort((a, b) => a.date.compareTo(b.date));
        final dataPoints = sortedSnapshots
            .map(
              (snapshot) => BurndownDataPoint(
                date: _dateOnly(snapshot.date),
                remainingHours: snapshot.remainingHours,
                actualHours: snapshot.remainingHours,
              ),
            )
            .toList();

        final latestRemaining = sortedSnapshots.last.remainingHours;
        final loggedHours =
            (targetHours - latestRemaining).clamp(0.0, targetHours).toDouble();
        final stats = _buildStatsFromProgress(
          sprint: sprint,
          targetHours: targetHours,
          loggedHours: loggedHours,
          remainingHours: latestRemaining.clamp(0.0, targetHours).toDouble(),
        );

        return SprintBurndownComputedData(dataPoints: dataPoints, stats: stats);
      }

      // Sprint-level logs are much cheaper than N calls by card.
      final timeLogs = await ref.watch(sprintTimeLogsProvider(sprintId).future);
      final completedLogs = timeLogs.where((log) => !log.isActive).toList();

      final totalLoggedHours = completedLogs.fold<double>(
        0,
        (sum, log) => sum + log.durationHours,
      );

      // If sprint hasn't started yet, keep chart empty and stats at target.
      if (sprint.status == SprintStatus.planning ||
          DateTime.now().isBefore(sprint.startDate)) {
        final stats = _buildStatsFromProgress(
          sprint: sprint,
          targetHours: targetHours,
          loggedHours: 0,
          remainingHours: targetHours,
        );
        return SprintBurndownComputedData(dataPoints: [], stats: stats);
      }

      final dailyLoggedHours = <DateTime, double>{};
      for (final log in completedLogs) {
        final logDate = _dateOnly(log.endTime ?? log.startTime);
        dailyLoggedHours[logDate] = (dailyLoggedHours[logDate] ?? 0) + log.durationHours;
      }

      final startDay = _dateOnly(sprint.startDate);

      // For completed sprints, extend past endDate if there are later logs
      // (e.g. last-minute work logged after the sprint was officially closed).
      DateTime endCap;
      if (sprint.status == SprintStatus.completed) {
        final latestLogDate = completedLogs.isEmpty
            ? sprint.endDate
            : completedLogs
                .map((log) => log.endTime ?? log.startTime)
                .reduce((a, b) => a.isAfter(b) ? a : b);
        endCap = latestLogDate.isAfter(sprint.endDate)
            ? latestLogDate
            : sprint.endDate;
      } else {
        endCap = DateTime.now();
      }
      final endDay = _dateOnly(endCap);

      final dataPoints = <BurndownDataPoint>[];
      if (!endDay.isBefore(startDay)) {
        var remainingHours = targetHours;
        dataPoints.add(
          BurndownDataPoint(
            date: startDay,
            remainingHours: remainingHours,
            actualHours: remainingHours,
          ),
        );

        var currentDay = startDay.add(const Duration(days: 1));
        while (!currentDay.isAfter(endDay)) {
          final loggedHours = dailyLoggedHours[currentDay] ?? 0;
          remainingHours = (remainingHours - loggedHours).clamp(0.0, targetHours).toDouble();
          dataPoints.add(
            BurndownDataPoint(
              date: currentDay,
              remainingHours: remainingHours,
              actualHours: remainingHours,
            ),
          );
          currentDay = currentDay.add(const Duration(days: 1));
        }
      }

      final remainingFromTarget = (targetHours - totalLoggedHours)
          .clamp(0.0, targetHours)
          .toDouble();
      final stats = _buildStatsFromProgress(
        sprint: sprint,
        targetHours: targetHours,
        loggedHours: totalLoggedHours,
        remainingHours: remainingFromTarget,
      );

      return SprintBurndownComputedData(dataPoints: dataPoints, stats: stats);
    });

/// Provider for burndown chart data for a specific sprint
final sprintBurndownProvider =
    FutureProvider.family<List<BurndownDataPoint>, String>((
      ref,
      sprintId,
    ) async {
      final burndown = await ref.watch(
        sprintBurndownComputedProvider(sprintId).future,
      );
      return burndown.dataPoints;
    });

/// Provider for burndown summary statistics
final sprintBurndownStatsProvider = FutureProvider.family<BurndownStats, String>((
  ref,
  sprintId,
) async {
  final burndown = await ref.watch(
    sprintBurndownComputedProvider(sprintId).future,
  );
  return burndown.stats;
});

/// Burndown statistics
class BurndownStats {
  final double targetHours;
  final double loggedHours;
  final double remainingHours;
  final double percentComplete;
  final bool isOnTrack;
  final int daysRemaining;
  final int cardsCount;

  BurndownStats({
    required this.targetHours,
    required this.loggedHours,
    required this.remainingHours,
    required this.percentComplete,
    required this.isOnTrack,
    required this.daysRemaining,
    required this.cardsCount,
  });
}
