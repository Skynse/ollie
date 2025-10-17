import '../models/sprint.dart';
import '../models/time_log.dart';
import '../models/burndown_snapshot.dart';

/// Abstract repository interface for sprint management
abstract class SprintRepository {
  // Sprint operations
  Future<Sprint> getSprint(String sprintId);
  Future<List<Sprint>> getSprintsByBoard(String boardId);
  Future<Sprint?> getActiveSprint(String boardId);
  Future<Sprint> createSprint(Sprint sprint);
  Future<Sprint> updateSprint(Sprint sprint);
  Future<void> deleteSprint(String sprintId);

  // Time log operations
  Future<TimeLog> getTimeLog(String timeLogId);
  Future<List<TimeLog>> getTimeLogsByCard(String cardId);
  Future<List<TimeLog>> getTimeLogsBySprint(String sprintId);
  Future<TimeLog?> getActiveTimeLog(String userId);
  Future<TimeLog> createTimeLog(TimeLog timeLog);
  Future<TimeLog> updateTimeLog(TimeLog timeLog);
  Future<void> deleteTimeLog(String timeLogId);

  // Burndown snapshot operations
  Future<BurndownSnapshot> getBurndownSnapshot(String snapshotId);
  Future<List<BurndownSnapshot>> getBurndownSnapshotsBySprint(String sprintId);
  Future<BurndownSnapshot> createBurndownSnapshot(BurndownSnapshot snapshot);
  Future<void> deleteBurndownSnapshot(String snapshotId);
}
