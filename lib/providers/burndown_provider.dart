import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sprint.dart';
import '../models/card.dart';
import '../components/burndown_chart.dart';
import 'sprint_provider.dart';
import 'boards_provider.dart';

/// Provider for burndown chart data for a specific sprint
final sprintBurndownProvider =
    FutureProvider.family<List<BurndownDataPoint>, String>((
      ref,
      sprintId,
    ) async {
      final repository = ref.read(sprintRepositoryProvider);
      final boardRepository = ref.read(boardRepositoryProvider);

      // Get the sprint
      final sprint = await repository.getSprint(sprintId);

      // If sprint hasn't started yet, return empty data
      if (sprint.status == SprintStatus.planning ||
          DateTime.now().isBefore(sprint.startDate)) {
        return [];
      }

      // Get all cards in the sprint
      final cards = <Card>[];
      for (final cardId in sprint.cardIds) {
        try {
          final card = await boardRepository.getCard(cardId);
          cards.add(card);
        } catch (e) {
          // Skip cards that can't be loaded
          continue;
        }
      }

      // Use sprint's target hours
      final targetHours = sprint.targetHours;

      // Get time logs per card to calculate remaining work
      final Map<String, double> cardLoggedHours = {};
      final Map<DateTime, double> dailyLoggedHours = {};

      for (final card in cards) {
        try {
          final timeLogs = await repository.getTimeLogsByCard(card.id);

          // Group time logs by date and sum hours per card
          // Include ALL time logs for cards in this sprint
          for (final log in timeLogs) {
            if (!log.isActive) {
              // Track total logged per card
              cardLoggedHours[card.id] =
                  (cardLoggedHours[card.id] ?? 0) + log.durationHours;

              // Use the end time's date (when work was completed)
              final logDate = log.endTime ?? log.startTime;
              final dateKey = DateTime(
                logDate.year,
                logDate.month,
                logDate.day,
              );

              dailyLoggedHours[dateKey] =
                  (dailyLoggedHours[dateKey] ?? 0) + log.durationHours;
            }
          }
        } catch (e) {
          // Skip if time logs can't be loaded
          continue;
        }
      }

      // Generate burndown data points
      final dataPoints = <BurndownDataPoint>[];
      final now = DateTime.now();
      final endDate = sprint.status == SprintStatus.completed
          ? sprint.endDate
          : now;

      // Start from sprint start date
      DateTime currentDate = DateTime(
        sprint.startDate.year,
        sprint.startDate.month,
        sprint.startDate.day,
      );

      double remainingHours = targetHours;

      // Add initial point (day 0) - start with target hours
      dataPoints.add(
        BurndownDataPoint(
          date: currentDate,
          remainingHours: targetHours,
          actualHours: targetHours,
        ),
      );

      // Add data points for each day
      while (currentDate.isBefore(endDate) ||
          currentDate.isAtSameMomentAs(endDate)) {
        currentDate = currentDate.add(const Duration(days: 1));

        // Subtract logged hours for this day
        final loggedHours = dailyLoggedHours[currentDate] ?? 0;
        remainingHours = (remainingHours - loggedHours).clamp(0, targetHours);

        dataPoints.add(
          BurndownDataPoint(
            date: currentDate,
            remainingHours: remainingHours,
            actualHours: remainingHours,
          ),
        );

        // Stop if we've reached today (for active sprints)
        if (sprint.status == SprintStatus.active &&
            currentDate.isAtSameMomentAs(
              DateTime(now.year, now.month, now.day),
            )) {
          break;
        }
      }

      return dataPoints;
    });

/// Provider for burndown summary statistics
final sprintBurndownStatsProvider = FutureProvider.family<BurndownStats, String>((
  ref,
  sprintId,
) async {
  final repository = ref.read(sprintRepositoryProvider);
  final boardRepository = ref.read(boardRepositoryProvider);

  final sprint = await repository.getSprint(sprintId);

  // Get all cards in the sprint
  final cards = <Card>[];
  for (final cardId in sprint.cardIds) {
    try {
      final card = await boardRepository.getCard(cardId);
      cards.add(card);
    } catch (e) {
      continue;
    }
  }

  // Use sprint's target hours
  final targetHours = sprint.targetHours;

  // Calculate logged hours and remaining work per card
  final Map<String, double> cardLoggedHours = {};
  for (final card in cards) {
    try {
      final timeLogs = await repository.getTimeLogsByCard(card.id);
      // Count ALL time logs for this card (not filtered by sprint)
      final logged = timeLogs
          .where((log) => !log.isActive)
          .fold<double>(0, (sum, log) => sum + log.durationHours);
      cardLoggedHours[card.id] = logged;
    } catch (e) {
      continue;
    }
  }

  // Total logged hours
  final totalLoggedHours = cardLoggedHours.values.fold<double>(
    0,
    (sum, hours) => sum + hours,
  );

  // Calculate remaining work: for each card, use (estimate - logged) or estimate
  double remainingHours = 0;
  for (final card in cards) {
    final estimated = card.estimatedHours ?? 0;
    final logged = cardLoggedHours[card.id] ?? 0;
    remainingHours += (estimated - logged).clamp(0, estimated);
  }

  final percentComplete = targetHours > 0
      ? (totalLoggedHours / targetHours * 100).toDouble()
      : 0.0;

  // Calculate if on track
  final now = DateTime.now();
  final sprintDuration = sprint.endDate.difference(sprint.startDate).inDays;
  final daysElapsed = now
      .difference(sprint.startDate)
      .inDays
      .clamp(0, sprintDuration);
  final expectedProgress = sprintDuration > 0
      ? daysElapsed / sprintDuration
      : 0;
  final actualProgress = targetHours > 0 ? totalLoggedHours / targetHours : 0;

  final isOnTrack = actualProgress >= expectedProgress - 0.1; // 10% tolerance

  return BurndownStats(
    targetHours: targetHours.toDouble(),
    loggedHours: totalLoggedHours.toDouble(),
    remainingHours: remainingHours,
    percentComplete: percentComplete,
    isOnTrack: isOnTrack,
    daysRemaining: sprint.daysRemaining.toInt(),
    cardsCount: cards.length,
  );
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
