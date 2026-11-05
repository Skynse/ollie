import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../database/database_helper.dart';
import '../../database/json_helpers.dart';
import '../../models/board.dart';
import '../../models/board_column.dart';
import '../../models/card.dart';
import '../../models/checklist.dart';
import '../../services/local_change_bus.dart';
import '../../services/realtime_service.dart';
import '../board_repository.dart';

class LocalBoardRepository implements BoardRepository {
  LocalBoardRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  static const _uuid = Uuid();

  Future<Database> get _db => _databaseHelper.database;

  void _emit(
    RealtimeEventType type,
    String collection,
    String id,
    Map<String, dynamic>? data,
  ) {
    LocalChangeBus.instance.emit(
      type: type,
      collection: collection,
      documentId: id,
      data: data,
    );
  }

  Board _boardFromRow(Map<String, dynamic> row) {
    return Board.fromJson({
      ...rowWithId(row),
      'archived': (row['archived'] as int? ?? 0) == 1,
      '\$createdAt': row['created_at'],
      '\$updatedAt': row['updated_at'],
    });
  }

  BoardColumn _columnFromRow(Map<String, dynamic> row) {
    return BoardColumn.fromJson({
      'id': row['id'],
      'boardId': row['board_id'],
      'name': row['name'],
      'position': row['position'],
      'color': row['color'],
      'wipLimit': row['wip_limit'],
    });
  }

  Map<String, dynamic> _cardRow(Card card, String id, {String? now}) {
    final timestamp = now ?? nowIso();
    return {
      'id': id,
      'column_id': card.columnId,
      'title': card.title,
      'description': card.description,
      'priority': card.priority.toJson(),
      'due_date': card.dueDate?.toIso8601String(),
      'estimated_hours': card.estimatedHours,
      'total_logged_hours': card.totalLoggedHours,
      'sprint_id': card.sprintId,
      'rank': card.rank,
      'completed': card.completed ? 1 : 0,
      'subtask_count': card.subtaskCount,
      'completed_subtask_count': card.completedSubtaskCount,
      'created_at': card.createdAt.toUtc().toIso8601String(),
      'updated_at': timestamp,
    };
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

  Future<String?> _boardIdForColumn(Database db, String columnId) async {
    final rows = await db.query(
      'columns',
      columns: ['board_id'],
      where: 'id = ?',
      whereArgs: [columnId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['board_id'] as String;
  }

  Future<String?> _boardIdForCard(Database db, String cardId) async {
    final rows = await db.rawQuery(
      'SELECT columns.board_id FROM cards '
      'INNER JOIN columns ON cards.column_id = columns.id '
      'WHERE cards.id = ? LIMIT 1',
      [cardId],
    );
    return rows.isEmpty ? null : rows.first['board_id'] as String;
  }

  Map<String, dynamic> _cardEventData(Card card, String? boardId) {
    return {...card.toJson(), 'boardId': boardId};
  }

  @override
  Future<Board> getBoard(String boardId) async {
    final db = await _db;
    final rows = await db.query(
      'boards',
      where: 'id = ?',
      whereArgs: [boardId],
      limit: 1,
    );
    if (rows.isEmpty) throw Exception('Board not found');
    return _boardFromRow(rows.first);
  }

  @override
  Future<List<Board>> getAllBoards() async {
    final db = await _db;
    final rows = await db.query('boards', orderBy: 'updated_at DESC');
    return rows.map(_boardFromRow).toList();
  }

  @override
  Future<Board> createBoard(Board board) async {
    final db = await _db;
    final id = board.id.isEmpty ? _uuid.v4() : board.id;
    final now = nowIso();

    await db.insert('boards', {
      'id': id,
      'name': board.name,
      'description': board.description,
      'archived': board.archived ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    });

    final created = await getBoard(id);
    _emit(RealtimeEventType.create, 'boards', id, created.toJson());
    return created;
  }

  @override
  Future<Board> updateBoard(Board board) async {
    final db = await _db;
    await db.update(
      'boards',
      {
        'name': board.name,
        'description': board.description,
        'archived': board.archived ? 1 : 0,
        'updated_at': nowIso(),
      },
      where: 'id = ?',
      whereArgs: [board.id],
    );

    final updated = await getBoard(board.id);
    _emit(RealtimeEventType.update, 'boards', board.id, updated.toJson());
    return updated;
  }

  @override
  Future<void> deleteBoard(String boardId) async {
    final db = await _db;
    await db.delete('boards', where: 'id = ?', whereArgs: [boardId]);
    _emit(RealtimeEventType.delete, 'boards', boardId, null);
  }

  @override
  Future<void> archiveBoard(String boardId) async {
    final board = await getBoard(boardId);
    await updateBoard(board.copyWith(archived: true));
  }

  @override
  Future<void> unarchiveBoard(String boardId) async {
    final board = await getBoard(boardId);
    await updateBoard(board.copyWith(archived: false));
  }

  @override
  Future<BoardColumn> getColumn(String columnId) async {
    final db = await _db;
    final rows = await db.query(
      'columns',
      where: 'id = ?',
      whereArgs: [columnId],
      limit: 1,
    );
    if (rows.isEmpty) throw Exception('Column not found');
    return _columnFromRow(rows.first);
  }

  @override
  Future<List<BoardColumn>> getColumnsByBoard(String boardId) async {
    final db = await _db;
    final rows = await db.query(
      'columns',
      where: 'board_id = ?',
      whereArgs: [boardId],
      orderBy: 'position ASC',
    );
    return rows.map(_columnFromRow).toList();
  }

  @override
  Future<BoardColumn> createColumn(BoardColumn column) async {
    final db = await _db;
    final id = column.id.isEmpty ? _uuid.v4() : column.id;
    await db.insert('columns', {
      'id': id,
      'board_id': column.boardId,
      'name': column.name,
      'position': column.position,
      'color': column.color,
      'wip_limit': column.wipLimit,
    });

    final created = await getColumn(id);
    _emit(RealtimeEventType.create, 'columns', id, created.toJson());
    return created;
  }

  @override
  Future<BoardColumn> updateColumn(BoardColumn column) async {
    final db = await _db;
    await db.update(
      'columns',
      {
        'board_id': column.boardId,
        'name': column.name,
        'position': column.position,
        'color': column.color,
        'wip_limit': column.wipLimit,
      },
      where: 'id = ?',
      whereArgs: [column.id],
    );

    final updated = await getColumn(column.id);
    _emit(RealtimeEventType.update, 'columns', column.id, updated.toJson());
    return updated;
  }

  @override
  Future<void> deleteColumn(String columnId) async {
    final db = await _db;
    final boardId = await _boardIdForColumn(db, columnId);
    await db.delete('columns', where: 'id = ?', whereArgs: [columnId]);
    _emit(RealtimeEventType.delete, 'columns', columnId, {'boardId': boardId});
  }

  @override
  Future<void> reorderColumns(String boardId, List<String> columnIds) async {
    final db = await _db;
    // Move out of the way first so unique position constraints (if added
    // later) cannot collide mid-update.
    for (var i = 0; i < columnIds.length; i++) {
      await db.update(
        'columns',
        {'position': i + 1000},
        where: 'id = ?',
        whereArgs: [columnIds[i]],
      );
    }
    for (var i = 0; i < columnIds.length; i++) {
      await db.update(
        'columns',
        {'position': i},
        where: 'id = ?',
        whereArgs: [columnIds[i]],
      );
      final column = await getColumn(columnIds[i]);
      _emit(RealtimeEventType.update, 'columns', columnIds[i], column.toJson());
    }
  }

  @override
  Future<Card> getCard(String cardId) async {
    final db = await _db;
    final rows = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
      limit: 1,
    );
    if (rows.isEmpty) throw Exception('Card not found');
    return _cardFromRow(rows.first);
  }

  @override
  Future<List<Card>> getCardsByColumn(String columnId) async {
    final db = await _db;
    final rows = await db.query(
      'cards',
      where: 'column_id = ?',
      whereArgs: [columnId],
      orderBy: 'rank ASC',
    );
    return rows.map(_cardFromRow).toList();
  }

  @override
  Future<List<Card>> getCardsByBoard(String boardId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT cards.* FROM cards '
      'INNER JOIN columns ON cards.column_id = columns.id '
      'WHERE columns.board_id = ? ORDER BY cards.rank ASC',
      [boardId],
    );
    return rows.map(_cardFromRow).toList();
  }

  @override
  Future<Card> createCard(Card card) async {
    final db = await _db;
    final id = card.id.isEmpty ? _uuid.v4() : card.id;
    await db.insert('cards', _cardRow(card, id));

    final created = await getCard(id);
    final boardId = await _boardIdForColumn(db, created.columnId);
    _emit(
      RealtimeEventType.create,
      'cards',
      id,
      _cardEventData(created, boardId),
    );
    return created;
  }

  @override
  Future<Card> updateCard(Card card) async {
    final db = await _db;
    await db.update(
      'cards',
      _cardRow(card, card.id, now: nowIso()),
      where: 'id = ?',
      whereArgs: [card.id],
    );

    final updated = await getCard(card.id);
    final boardId = await _boardIdForColumn(db, updated.columnId);
    _emit(
      RealtimeEventType.update,
      'cards',
      card.id,
      _cardEventData(updated, boardId),
    );
    return updated;
  }

  @override
  Future<void> deleteCard(String cardId) async {
    final db = await _db;
    final boardId = await _boardIdForCard(db, cardId);
    await db.delete('cards', where: 'id = ?', whereArgs: [cardId]);
    _emit(RealtimeEventType.delete, 'cards', cardId, {'boardId': boardId});
  }

  @override
  Future<void> moveCard({
    required String cardId,
    required String targetColumnId,
    required String newRank,
  }) async {
    final db = await _db;
    await db.update(
      'cards',
      {'column_id': targetColumnId, 'rank': newRank, 'updated_at': nowIso()},
      where: 'id = ?',
      whereArgs: [cardId],
    );

    final updated = await getCard(cardId);
    final boardId = await _boardIdForColumn(db, targetColumnId);
    _emit(
      RealtimeEventType.update,
      'cards',
      cardId,
      _cardEventData(updated, boardId),
    );
  }

  @override
  Future<Checklist> getChecklist(String checklistId) async {
    final db = await _db;
    final rows = await db.query(
      'checklists',
      where: 'id = ?',
      whereArgs: [checklistId],
      limit: 1,
    );
    if (rows.isEmpty) throw Exception('Checklist not found');
    return _checklistFromRow(rows.first);
  }

  @override
  Future<List<Checklist>> getChecklistsByCard(String cardId) async {
    final db = await _db;
    final rows = await db.query(
      'checklists',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
    return rows.map(_checklistFromRow).toList();
  }

  Checklist _checklistFromRow(Map<String, dynamic> row) {
    return Checklist.fromJson({
      'id': row['id'],
      'cardId': row['card_id'],
      'title': row['title'],
      'items': jsonDecode(row['items'] as String),
    });
  }

  @override
  Future<Checklist> createChecklist(Checklist checklist) async {
    final db = await _db;
    final id = checklist.id.isEmpty ? _uuid.v4() : checklist.id;
    await db.insert('checklists', {
      'id': id,
      'card_id': checklist.cardId,
      'title': checklist.title,
      'items': jsonEncode(
        checklist.items.map((item) => jsonEncode(item.toJson())).toList(),
      ),
    });
    return getChecklist(id);
  }

  @override
  Future<Checklist> updateChecklist(Checklist checklist) async {
    final db = await _db;
    await db.update(
      'checklists',
      {
        'card_id': checklist.cardId,
        'title': checklist.title,
        'items': jsonEncode(
          checklist.items.map((item) => jsonEncode(item.toJson())).toList(),
        ),
      },
      where: 'id = ?',
      whereArgs: [checklist.id],
    );
    return getChecklist(checklist.id);
  }

  @override
  Future<void> deleteChecklist(String checklistId) async {
    final db = await _db;
    await db.delete('checklists', where: 'id = ?', whereArgs: [checklistId]);
  }
}
