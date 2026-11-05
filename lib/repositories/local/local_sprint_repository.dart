import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_helper.dart';
import '../../database/json_helpers.dart';
import '../../models/burndown_snapshot.dart';
import '../../models/card.dart';
import '../../models/sprint.dart';
import '../../models/time_log.dart';
import '../../services/local_change_bus.dart';
import '../../services/realtime_service.dart';
import '../sprint_repository.dart';

class LocalSprintRepository implements SprintRepository {
  LocalSprintRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  static const _uuid = Uuid();

  Future<Database> get _db => _databaseHelper.database;

  Sprint _sprintFromRow(Map<String, dynamic> row, List<String> cardIds) {
    return Sprint.fromJson({
      'id': row['id'],
      'boardId': row['board_id'],
      'name': row['name'],
      'goal': row['goal'],
      'startDate': row['start_date'],
      'endDate': row['end_date'],
      'targetHours': row['target_hours'],
      'status': row['status'],
      'cardIds': cardIds,
      '\$createdAt': row['created_at'],
      '\$updatedAt': row['updated_at'],
    });
  }

  TimeLog _timeLogFromRow(Map<String, dynamic> row) {
    return TimeLog.fromJson({
      'id': row['id'],
      'cardId': row['card_id'],
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

  Card _cardFromRow(Map<String, dynamic> row) {
    return Card.fromJson({
      'id': row['id'],
      'columnId': row['column_id'],
      'title': row['title'],
      'description': row['description'],
      'priority': row['priority'],
      'dueDate': row['due_date'],
      'estimatedHours': row['estimated_hours'],
      'totalLoggedHours': row['total_logged_hours'],
      'sprintId': row['sprint_id'],
      'rank': row['rank'],
      'completed': (row['completed'] as int? ?? 0) == 1,
      'subtaskCount': row['subtask_count'],
      'completedSubtaskCount': row['completed_subtask_count'],
      '\$createdAt': row['created_at'],
      '\$updatedAt': row['updated_at'],
    });
  }

  Future<List<String>> _cardIdsForSprint(Database db, String sprintId) async {
    final rows = await db.query(
      'cards',
      columns: ['id'],
      where: 'sprint_id = ?',
      whereArgs: [sprintId],
      orderBy: 'rank ASC',
    );
    return rows.map((row) => row['id'] as String).toList();
  }

  /// Recomputes the card's denormalized total from `time_logs`.
  Future<void> _recalculateCardTotal(DatabaseExecutor db, String cardId) async {
    final totals = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_minutes), 0) AS minutes '
      'FROM time_logs WHERE card_id = ?',
      [cardId],
    );
    final minutes = (totals.first['minutes'] as num?)?.toDouble() ?? 0;
    final hours = minutes / 60.0;
    await db.update(
      'cards',
      {'total_logged_hours': hours, 'updated_at': nowIso()},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  /// Emits a card update so every listening board view refreshes immediately.
  Future<void> _emitCardUpdate(Database db, String cardId) async {
    final rows = await db.rawQuery(
      'SELECT cards.*, columns.board_id AS board_id FROM cards '
      'INNER JOIN columns ON cards.column_id = columns.id '
      'WHERE cards.id = ? LIMIT 1',
      [cardId],
    );
    if (rows.isEmpty) return;
    final card = _cardFromRow(rows.first);
    LocalChangeBus.instance.emit(
      type: RealtimeEventType.update,
      collection: 'cards',
      documentId: cardId,
      data: {...card.toJson(), 'boardId': rows.first['board_id']},
    );
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
    final cardIds = await _cardIdsForSprint(db, sprintId);
    return _sprintFromRow(rows.first, cardIds);
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
    if (rows.isEmpty) return [];

    final cardRows = await db.rawQuery(
      'SELECT cards.id AS card_id, cards.sprint_id AS sprint_id FROM cards '
      'INNER JOIN sprints ON cards.sprint_id = sprints.id '
      'WHERE sprints.board_id = ? ORDER BY cards.rank ASC',
      [boardId],
    );
    final bySprint = <String, List<String>>{};
    for (final row in cardRows) {
      final sprintId = row['sprint_id'] as String;
      (bySprint[sprintId] ??= []).add(row['card_id'] as String);
    }

    return rows
        .map((row) => _sprintFromRow(row, bySprint[row['id']] ?? const []))
        .toList();
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
    final cardIds = await _cardIdsForSprint(db, rows.first['id'] as String);
    return _sprintFromRow(rows.first, cardIds);
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
    final affectedCards = await db.query(
      'cards',
      columns: ['id'],
      where: 'sprint_id = ?',
      whereArgs: [sprintId],
    );
    await db.transaction((txn) async {
      // Keep cards and logs usable after their sprint is deleted.
      await txn.update(
        'cards',
        {'sprint_id': null},
        where: 'sprint_id = ?',
        whereArgs: [sprintId],
      );
      await txn.update(
        'time_logs',
        {'sprint_id': null},
        where: 'sprint_id = ?',
        whereArgs: [sprintId],
      );
      await txn.delete('sprints', where: 'id = ?', whereArgs: [sprintId]);
    });
    for (final row in affectedCards) {
      await _emitCardUpdate(db, row['id'] as String);
    }
  }

  @override
  Future<void> addCardToSprint(String sprintId, String cardId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'cards',
        {'sprint_id': sprintId, 'updated_at': nowIso()},
        where: 'id = ?',
        whereArgs: [cardId],
      );
      await txn.update(
        'sprints',
        {'updated_at': nowIso()},
        where: 'id = ?',
        whereArgs: [sprintId],
      );
      await _recalculateCardTotal(txn, cardId);
    });
    await _emitCardUpdate(db, cardId);
  }

  @override
  Future<void> removeCardFromSprint(String sprintId, String cardId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'cards',
        {'sprint_id': null, 'updated_at': nowIso()},
        where: 'id = ? AND sprint_id = ?',
        whereArgs: [cardId, sprintId],
      );
      await txn.update(
        'sprints',
        {'updated_at': nowIso()},
        where: 'id = ?',
        whereArgs: [sprintId],
      );
      await _recalculateCardTotal(txn, cardId);
    });
    await _emitCardUpdate(db, cardId);
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
    return rows.map(_timeLogFromRow).toList();
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
    return rows.map(_timeLogFromRow).toList();
  }

  @override
  Future<TimeLog> createTimeLog(TimeLog timeLog) async {
    final db = await _db;
    final id = timeLog.id.isEmpty ? _uuid.v4() : timeLog.id;
    final now = nowIso();
    await db.transaction((txn) async {
      await txn.insert('time_logs', {
        'id': id,
        'card_id': timeLog.cardId,
        'start_time': timeLog.startTime.toIso8601String(),
        'end_time': timeLog.endTime?.toIso8601String(),
        'duration_minutes': timeLog.durationMinutes,
        'notes': timeLog.notes,
        'is_active': timeLog.isActive ? 1 : 0,
        'sprint_id': timeLog.sprintId,
        'created_at': now,
        'updated_at': now,
      });
      await _recalculateCardTotal(txn, timeLog.cardId);
    });
    await _emitCardUpdate(db, timeLog.cardId);
    return getTimeLog(id);
  }

  @override
  Future<TimeLog> updateTimeLog(TimeLog timeLog) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'time_logs',
        {
          'card_id': timeLog.cardId,
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
      await _recalculateCardTotal(txn, timeLog.cardId);
    });
    await _emitCardUpdate(db, timeLog.cardId);
    return getTimeLog(timeLog.id);
  }

  @override
  Future<void> deleteTimeLog(String timeLogId) async {
    final db = await _db;
    final log = await getTimeLog(timeLogId);
    await db.transaction((txn) async {
      await txn.delete('time_logs', where: 'id = ?', whereArgs: [timeLogId]);
      await _recalculateCardTotal(txn, log.cardId);
    });
    await _emitCardUpdate(db, log.cardId);
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
    return rows.map(_snapshotFromRow).toList();
  }

  @override
  Future<BurndownSnapshot> createBurndownSnapshot(
    BurndownSnapshot snapshot,
  ) async {
    final db = await _db;
    final id = snapshot.id.isEmpty ? _uuid.v4() : snapshot.id;
    await db.insert('burndown_snapshots', {
      'id': id,
      'sprint_id': snapshot.sprintId,
      'date': snapshot.date.toIso8601String(),
      'remaining_hours': snapshot.remainingHours,
      'completed_hours': snapshot.completedHours,
      'total_cards': snapshot.totalCards,
      'completed_cards': snapshot.completedCards,
      'scope_change_hours': snapshot.scopeChangeHours,
      'created_at': nowIso(),
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
