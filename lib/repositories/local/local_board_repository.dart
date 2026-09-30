import 'dart:convert';

import '../../models/board.dart';
import '../../models/board_column.dart';
import '../../models/card.dart';
import '../../models/label.dart';
import '../../models/comment.dart';
import '../../models/checklist.dart';
import '../../database/database_helper.dart';
import '../../database/json_helpers.dart';
import '../../services/local_change_bus.dart';
import '../../services/realtime_service.dart';
import '../board_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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

  Board _boardFromRow(Map<String, dynamic> row, List<String> memberIds) {
    return Board.fromJson({
      ...rowWithId(row),
      'createdBy': row['created_by'],
      'members': memberIds,
      'archived': (row['archived'] as int? ?? 0) == 1,
      '\$createdAt': row['created_at'],
      '\$updatedAt': row['updated_at'],
    });
  }

  Future<List<String>> _memberIds(Database db, String boardId) async {
    final rows = await db.query(
      'board_members',
      columns: ['user_id'],
      where: 'board_id = ?',
      whereArgs: [boardId],
    );
    return rows.map((r) => r['user_id'] as String).toList();
  }

  Future<void> _setMembers(
    Database db,
    String boardId,
    List<String> memberIds,
  ) async {
    await db.delete(
      'board_members',
      where: 'board_id = ?',
      whereArgs: [boardId],
    );
    for (final memberId in memberIds.toSet()) {
      await db.insert('board_members', {
        'board_id': boardId,
        'user_id': memberId,
      });
    }
  }

  Map<String, dynamic> _cardRow(Card card, String id) {
    return {
      'id': id,
      'column_id': card.columnId,
      'title': card.title,
      'description': card.description,
      'position': card.position,
      'assignee_ids': encodeStringList(card.assigneeIds),
      'label_ids': encodeStringList(card.labelIds),
      'priority': card.priority.toJson(),
      'due_date': card.dueDate?.toIso8601String(),
      'comment_count': card.commentCount,
      'created_by': card.createdBy,
      'estimated_hours': card.estimatedHours,
      'total_logged_hours': card.totalLoggedHours,
      'sprint_id': card.sprintId,
      'rank': card.rank,
      'completed': card.completed ? 1 : 0,
      'subtask_count': card.subtaskCount,
      'completed_subtask_count': card.completedSubtaskCount,
      'created_at': card.createdAt.toUtc().toIso8601String(),
      'updated_at': card.updatedAt.toUtc().toIso8601String(),
    };
  }

  Card _cardFromRow(Map<String, dynamic> row) {
    return Card.fromJson({
      'id': row['id'],
      'columnId': row['column_id'],
      'title': row['title'],
      'description': row['description'],
      'position': row['position'],
      'assigneeIds': decodeStringList(row['assignee_ids']),
      'labelIds': decodeStringList(row['label_ids']),
      'priority': row['priority'],
      'dueDate': row['due_date'],
      'commentCount': row['comment_count'],
      'createdBy': row['created_by'],
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
    final members = await _memberIds(db, boardId);
    return _boardFromRow(rows.first, members);
  }

  @override
  Future<List<Board>> getAllBoards() async {
    final db = await _db;
    final rows = await db.query('boards', orderBy: 'updated_at DESC');

    final boards = <Board>[];
    for (final row in rows) {
      final members = await _memberIds(db, row['id'] as String);
      boards.add(_boardFromRow(row, members));
    }
    return boards;
  }

  @override
  Future<List<Board>> getBoardsByUser(String userId) async {
    return getAllBoards();
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
      'created_by': board.createdBy,
      'column_ids': encodeStringList(board.columnIds),
      'archived': board.archived ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    });

    await _setMembers(db, id, board.memberIds);

    final created = await getBoard(id);
    _emit(
      RealtimeEventType.create,
      'boards',
      id,
      {...created.toJson(), 'id': id},
    );
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
        'created_by': board.createdBy,
        'column_ids': encodeStringList(board.columnIds),
        'archived': board.archived ? 1 : 0,
        'updated_at': nowIso(),
      },
      where: 'id = ?',
      whereArgs: [board.id],
    );
    await _setMembers(db, board.id, board.memberIds);

    final updated = await getBoard(board.id);
    _emit(
      RealtimeEventType.update,
      'boards',
      board.id,
      {...updated.toJson(), 'id': board.id},
    );
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
  Future<void> addMember(String boardId, String userId) async {
    final board = await getBoard(boardId);
    if (board.memberIds.contains(userId)) return;
    await updateBoard(
      board.copyWith(memberIds: [...board.memberIds, userId]),
    );
  }

  @override
  Future<void> removeMember(String boardId, String userId) async {
    final board = await getBoard(boardId);
    await updateBoard(
      board.copyWith(
        memberIds: board.memberIds.where((id) => id != userId).toList(),
      ),
    );
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
    final row = rows.first;
    return BoardColumn.fromJson({
      'id': row['id'],
      'boardId': row['board_id'],
      'name': row['name'],
      'position': row['position'],
      'color': row['color'],
      'wipLimit': row['wip_limit'],
      'cardIds': decodeStringList(row['card_ids']),
    });
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
    return rows
        .map(
          (row) => BoardColumn.fromJson({
            'id': row['id'],
            'boardId': row['board_id'],
            'name': row['name'],
            'position': row['position'],
            'color': row['color'],
            'wipLimit': row['wip_limit'],
            'cardIds': decodeStringList(row['card_ids']),
          }),
        )
        .toList();
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
      'card_ids': encodeStringList(column.cardIds),
    });

    final created = await getColumn(id);
    _emit(
      RealtimeEventType.create,
      'columns',
      id,
      created.toJson()..['id'] = id,
    );
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
        'card_ids': encodeStringList(column.cardIds),
      },
      where: 'id = ?',
      whereArgs: [column.id],
    );

    final updated = await getColumn(column.id);
    _emit(
      RealtimeEventType.update,
      'columns',
      column.id,
      {...updated.toJson(), 'id': column.id},
    );
    return updated;
  }

  @override
  Future<void> deleteColumn(String columnId) async {
    final db = await _db;
    await db.delete('columns', where: 'id = ?', whereArgs: [columnId]);
    _emit(RealtimeEventType.delete, 'columns', columnId, null);
  }

  @override
  Future<void> reorderColumns(String boardId, List<String> columnIds) async {
    final db = await _db;
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
      _emit(
        RealtimeEventType.update,
        'columns',
        columnIds[i],
        {...column.toJson(), 'id': columnIds[i]},
      );
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
    return rows.map((row) => _cardFromRow(row)).toList();
  }

  @override
  Future<Card> createCard(Card card) async {
    final db = await _db;
    final id = card.id.isEmpty ? _uuid.v4() : card.id;
    await db.insert('cards', _cardRow(card, id));

    final created = await getCard(id);
    _emit(RealtimeEventType.create, 'cards', id, created.toJson()..['id'] = id);
    return created;
  }

  @override
  Future<Card> updateCard(Card card) async {
    final db = await _db;
    await db.update(
      'cards',
      {
        ..._cardRow(card, card.id),
        'updated_at': nowIso(),
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );

    final updated = await getCard(card.id);
    _emit(
      RealtimeEventType.update,
      'cards',
      card.id,
      {...updated.toJson(), 'id': card.id},
    );
    return updated;
  }

  @override
  Future<void> deleteCard(String cardId) async {
    final db = await _db;
    await db.delete('cards', where: 'id = ?', whereArgs: [cardId]);
    _emit(RealtimeEventType.delete, 'cards', cardId, null);
  }

  @override
  Future<void> moveCard({
    required String cardId,
    required String sourceColumnId,
    required String targetColumnId,
    required String newRank,
  }) async {
    final db = await _db;
    await db.update(
      'cards',
      {
        'column_id': targetColumnId,
        'rank': newRank,
        'updated_at': nowIso(),
      },
      where: 'id = ?',
      whereArgs: [cardId],
    );

    final updated = await getCard(cardId);
    _emit(
      RealtimeEventType.update,
      'cards',
      cardId,
      {...updated.toJson(), 'id': cardId},
    );
  }

  @override
  Future<void> reorderCards(String columnId, List<String> cardIds) async {
    final db = await _db;
    for (var i = 0; i < cardIds.length; i++) {
      await db.update(
        'cards',
        {'position': i, 'updated_at': nowIso()},
        where: 'id = ?',
        whereArgs: [cardIds[i]],
      );
    }
  }

  @override
  Future<Label> getLabel(String labelId) async {
    final db = await _db;
    final rows = await db.query(
      'labels',
      where: 'id = ?',
      whereArgs: [labelId],
      limit: 1,
    );
    if (rows.isEmpty) throw Exception('Label not found');
    final row = rows.first;
    return Label.fromJson({
      'id': row['id'],
      'boardId': row['board_id'],
      'name': row['name'],
      'color': row['color'],
    });
  }

  @override
  Future<List<Label>> getLabelsByBoard(String boardId) async {
    final db = await _db;
    final rows = await db.query(
      'labels',
      where: 'board_id = ?',
      whereArgs: [boardId],
    );
    return rows
        .map(
          (row) => Label.fromJson({
            'id': row['id'],
            'boardId': row['board_id'],
            'name': row['name'],
            'color': row['color'],
          }),
        )
        .toList();
  }

  @override
  Future<Label> createLabel(Label label) async {
    final db = await _db;
    final id = label.id.isEmpty ? _uuid.v4() : label.id;
    await db.insert('labels', {
      'id': id,
      'board_id': label.boardId,
      'name': label.name,
      'color': label.color,
    });
    return getLabel(id);
  }

  @override
  Future<Label> updateLabel(Label label) async {
    final db = await _db;
    await db.update(
      'labels',
      {
        'board_id': label.boardId,
        'name': label.name,
        'color': label.color,
      },
      where: 'id = ?',
      whereArgs: [label.id],
    );
    return getLabel(label.id);
  }

  @override
  Future<void> deleteLabel(String labelId) async {
    final db = await _db;
    await db.delete('labels', where: 'id = ?', whereArgs: [labelId]);
  }

  @override
  Future<Comment> getComment(String commentId) async {
    final db = await _db;
    final rows = await db.query(
      'comments',
      where: 'id = ?',
      whereArgs: [commentId],
      limit: 1,
    );
    if (rows.isEmpty) throw Exception('Comment not found');
    final row = rows.first;
    return Comment.fromJson({
      'id': row['id'],
      'cardId': row['card_id'],
      'userId': row['user_id'],
      'content': row['content'],
      '\$createdAt': row['created_at'],
      '\$updatedAt': row['updated_at'],
    });
  }

  @override
  Future<List<Comment>> getCommentsByCard(String cardId) async {
    final db = await _db;
    final rows = await db.query(
      'comments',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'created_at DESC',
    );
    return rows
        .map(
          (row) => Comment.fromJson({
            'id': row['id'],
            'cardId': row['card_id'],
            'userId': row['user_id'],
            'content': row['content'],
            '\$createdAt': row['created_at'],
            '\$updatedAt': row['updated_at'],
          }),
        )
        .toList();
  }

  @override
  Future<Comment> createComment(Comment comment) async {
    final db = await _db;
    final id = comment.id.isEmpty ? _uuid.v4() : comment.id;
    final now = nowIso();
    await db.insert('comments', {
      'id': id,
      'card_id': comment.cardId,
      'user_id': comment.userId,
      'content': comment.content,
      'created_at': now,
      'updated_at': null,
    });
    return getComment(id);
  }

  @override
  Future<Comment> updateComment(Comment comment) async {
    final db = await _db;
    await db.update(
      'comments',
      {
        'card_id': comment.cardId,
        'user_id': comment.userId,
        'content': comment.content,
        'updated_at': nowIso(),
      },
      where: 'id = ?',
      whereArgs: [comment.id],
    );
    return getComment(comment.id);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    final db = await _db;
    await db.delete('comments', where: 'id = ?', whereArgs: [commentId]);
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
    final row = rows.first;
    return Checklist.fromJson({
      'id': row['id'],
      'cardId': row['card_id'],
      'title': row['title'],
      'items': jsonDecode(row['items'] as String),
    });
  }

  @override
  Future<List<Checklist>> getChecklistsByCard(String cardId) async {
    final db = await _db;
    final rows = await db.query(
      'checklists',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
    return rows
        .map(
          (row) => Checklist.fromJson({
            'id': row['id'],
            'cardId': row['card_id'],
            'title': row['title'],
            'items': jsonDecode(row['items'] as String),
          }),
        )
        .toList();
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
