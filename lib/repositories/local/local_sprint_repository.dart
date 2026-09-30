import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_helper.dart';
import '../../database/json_helpers.dart';
import '../../models/burndown_snapshot.dart';
import '../../models/sprint.dart';
import '../../models/time_log.dart';
import '../sprint_repository.dart';

class LocalSprintRepository implements SprintRepository {
  LocalSprintRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  static const _uuid = Uuid();

  Future<Database> get _db => _databaseHelper.database;

  Sprint _sprintFromRow(Map<String, dynamic> row) {
    return Sprint.fromJson({
      'id': row['id'],
      'boardId': row['board_id'],
      'name': row['name'],
      'goal': row['goal'],
      'startDate': row['start_date'],
      'endDate': row['end_date'],
      'targetHours': row['target_hours'],
      'status': row['status'],
      'cardIds': decodeStringList(row['card_ids']),
      '\$createdAt': row['created_at'],
      '\$updatedAt': row['updated_at'],
    });
  }

  TimeLog _timeLogFromRow(Map<String, dynamic> row) {
    return TimeLog.fromJson({
      'id': row['id'],
      'cardId': row['card_id'],
      'userId': row['user_id'],
      'startTime': row['start_time'],
      'endTime': row['end_time'],
      'durationMinutes': row['duration_minutes'],
      'notes': row['notes'],
      'isActive': (row['is_active'] as int? ?? 0) == 1,
      'sprintId': row['sprint_id'],
      '\$createdAt': row['created_at'],
      '\$updatedAt': row['updated_at'],
    });
  }

  BurndownSnapshot _snapshotFromRow(Map<String, dynamic> row) {
    return BurndownSnapshot.fromJson({
      'id': row['id'],
      'sprintId': row['sprint_id'],
      'date': row['date'],
      'remainingHours': row['remaining_hours'],
      'completedHours': row['completed_hours'],
      'totalCards': row['total_cards'],
      'completedCards': row['completed_cards'],
      'scopeChangeHours': row['scope_change_hours'],
      '\$createdAt': row['created_at'],
    });
  }

  @override
  Future<Sprint> getSprint(String sprintId) async {
    final db = await _db;
    final rows = await db.query(
      'sprints',
      where: 'id = ?',
      whereArgs: [sprintId],
      limit: 1,
    );
    if (rows.isEmpty) throw Exception('Sprint not found');
    return _sprintFromRow(rows.first);
  }

  @override
  Future<List<Sprint>> getSprintsByBoard(String boardId) async {
    final db = await _db;
    final rows = await db.query(
      'sprints',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => _sprintFromRow(row)).toList();
  }

  @override
  Future<Sprint?> getActiveSprint(String boardId) async {
    final db = await _db;
    final rows = await db.query(
      'sprints',
      where: 'board_id = ? AND status = ?',
      whereArgs: [boardId, SprintStatus.active.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _sprintFromRow(rows.first);
  }

  @override
  Future<Sprint> createSprint(Sprint sprint) async {
    final db = await _db;
    final id = sprint.id.isEmpty ? _uuid.v4() : sprint.id;
    final now = nowIso();
    await db.insert('sprints', {
      'id': id,
      'board_id': sprint.boardId,
      'name': sprint.name,
      'goal': sprint.goal,
      'start_date': sprint.startDate.toIso8601String(),
      'end_date': sprint.endDate.toIso8601String(),
      'target_hours': sprint.targetHours,
      'status': sprint.status.name,
      'card_ids': encodeStringList(sprint.cardIds),
      'created_at': now,
      'updated_at': now,
    });
    return getSprint(id);
  }

  @override
  Future<Sprint> updateSprint(Sprint sprint) async {
    final db = await _db;
    await db.update(
      'sprints',
      {
        'board_id': sprint.boardId,
        'name': sprint.name,
        'goal': sprint.goal,
        'start_date': sprint.startDate.toIso8601String(),
        'end_date': sprint.endDate.toIso8601String(),
        'target_hours': sprint.targetHours,
        'status': sprint.status.name,
        'card_ids': encodeStringList(sprint.cardIds),
        'updated_at': nowIso(),
      },
      where: 'id = ?',
      whereArgs: [sprint.id],
    );
    return getSprint(sprint.id);
  }

  @override
  Future<void> deleteSprint(String sprintId) async {
    final db = await _db;
    await db.delete('sprints', where: 'id = ?', whereArgs: [sprintId]);
  }

  @override
  Future<TimeLog> getTimeLog(String timeLogId) async {
    final db = await _db;
    final rows = await db.query(
      'time_logs',
      where: 'id = ?',
      whereArgs: [timeLogId],
      limit: 1,
    );
    if (rows.isEmpty) throw Exception('Time log not found');
    return _timeLogFromRow(rows.first);
  }

  @override
  Future<List<TimeLog>> getTimeLogsByCard(String cardId) async {
    final db = await _db;
    final rows = await db.query(
      'time_logs',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => _timeLogFromRow(row)).toList();
  }

  @override
  Future<List<TimeLog>> getTimeLogsBySprint(String sprintId) async {
    final db = await _db;
    final rows = await db.query(
      'time_logs',
      where: 'sprint_id = ?',
      whereArgs: [sprintId],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => _timeLogFromRow(row)).toList();
  }

  @override
  Future<TimeLog?> getActiveTimeLog(String userId) async {
    final db = await _db;
    final rows = await db.query(
      'time_logs',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _timeLogFromRow(rows.first);
  }

  @override
  Future<TimeLog> createTimeLog(TimeLog timeLog) async {
    final db = await _db;
    final id = timeLog.id.isEmpty ? _uuid.v4() : timeLog.id;
    final now = nowIso();
    await db.insert('time_logs', {
      'id': id,
      'card_id': timeLog.cardId,
      'user_id': timeLog.userId,
      'start_time': timeLog.startTime.toIso8601String(),
      'end_time': timeLog.endTime?.toIso8601String(),
      'duration_minutes': timeLog.durationMinutes,
      'notes': timeLog.notes,
      'is_active': timeLog.isActive ? 1 : 0,
      'sprint_id': timeLog.sprintId,
      'created_at': now,
      'updated_at': now,
    });
    return getTimeLog(id);
  }

  @override
  Future<TimeLog> updateTimeLog(TimeLog timeLog) async {
    final db = await _db;
    await db.update(
      'time_logs',
      {
        'card_id': timeLog.cardId,
        'user_id': timeLog.userId,
        'start_time': timeLog.startTime.toIso8601String(),
        'end_time': timeLog.endTime?.toIso8601String(),
        'duration_minutes': timeLog.durationMinutes,
        'notes': timeLog.notes,
        'is_active': timeLog.isActive ? 1 : 0,
        'sprint_id': timeLog.sprintId,
        'updated_at': nowIso(),
      },
      where: 'id = ?',
      whereArgs: [timeLog.id],
    );
    return getTimeLog(timeLog.id);
  }

  @override
  Future<void> deleteTimeLog(String timeLogId) async {
    final db = await _db;
    await db.delete('time_logs', where: 'id = ?', whereArgs: [timeLogId]);
  }

  @override
  Future<BurndownSnapshot> getBurndownSnapshot(String snapshotId) async {
    final db = await _db;
    final rows = await db.query(
      'burndown_snapshots',
      where: 'id = ?',
      whereArgs: [snapshotId],
      limit: 1,
    );
    if (rows.isEmpty) throw Exception('Snapshot not found');
    return _snapshotFromRow(rows.first);
  }

  @override
  Future<List<BurndownSnapshot>> getBurndownSnapshotsBySprint(
    String sprintId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'burndown_snapshots',
      where: 'sprint_id = ?',
      whereArgs: [sprintId],
      orderBy: 'date ASC',
    );
    return rows.map((row) => _snapshotFromRow(row)).toList();
  }

  @override
  Future<BurndownSnapshot> createBurndownSnapshot(
    BurndownSnapshot snapshot,
  ) async {
    final db = await _db;
    final id = snapshot.id.isEmpty ? _uuid.v4() : snapshot.id;
    final now = nowIso();
    await db.insert('burndown_snapshots', {
      'id': id,
      'sprint_id': snapshot.sprintId,
      'date': snapshot.date.toIso8601String(),
      'remaining_hours': snapshot.remainingHours,
      'completed_hours': snapshot.completedHours,
      'total_cards': snapshot.totalCards,
      'completed_cards': snapshot.completedCards,
      'scope_change_hours': snapshot.scopeChangeHours,
      'created_at': now,
    });
    return getBurndownSnapshot(id);
  }

  @override
  Future<void> deleteBurndownSnapshot(String snapshotId) async {
    final db = await _db;
    await db.delete(
      'burndown_snapshots',
      where: 'id = ?',
      whereArgs: [snapshotId],
    );
  }
}
