import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ollie_migration_');
    dbPath = '${tempDir.path}/v1.db';
    await DatabaseHelper.resetForTests();
    DatabaseHelper.testDatabasePath = dbPath;
  });

  tearDown(() async {
    await DatabaseHelper.resetForTests();
    DatabaseHelper.testDatabasePath = null;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> createV1Database() async {
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY, email TEXT NOT NULL UNIQUE, name TEXT NOT NULL,
            password_hash TEXT NOT NULL, password_salt TEXT NOT NULL,
            avatar_url TEXT, created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE boards (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT,
            created_by TEXT NOT NULL, column_ids TEXT NOT NULL DEFAULT '[]',
            archived INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE board_members (
            board_id TEXT NOT NULL, user_id TEXT NOT NULL,
            PRIMARY KEY (board_id, user_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE columns (
            id TEXT PRIMARY KEY, board_id TEXT NOT NULL, name TEXT NOT NULL,
            position INTEGER NOT NULL DEFAULT 0, color INTEGER NOT NULL,
            wip_limit INTEGER, card_ids TEXT NOT NULL DEFAULT '[]'
          )
        ''');
        await db.execute('''
          CREATE TABLE cards (
            id TEXT PRIMARY KEY, column_id TEXT NOT NULL, title TEXT NOT NULL,
            description TEXT, position INTEGER NOT NULL DEFAULT 0,
            assignee_ids TEXT NOT NULL DEFAULT '[]',
            label_ids TEXT NOT NULL DEFAULT '[]',
            priority TEXT NOT NULL DEFAULT 'low', due_date TEXT,
            comment_count INTEGER NOT NULL DEFAULT 0,
            created_by TEXT NOT NULL, estimated_hours REAL,
            total_logged_hours REAL NOT NULL DEFAULT 0, sprint_id TEXT,
            rank TEXT NOT NULL DEFAULT 'U', completed INTEGER NOT NULL DEFAULT 0,
            subtask_count INTEGER NOT NULL DEFAULT 0,
            completed_subtask_count INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL, updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE labels (
            id TEXT PRIMARY KEY, board_id TEXT NOT NULL, name TEXT NOT NULL,
            color INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE comments (
            id TEXT PRIMARY KEY, card_id TEXT NOT NULL, user_id TEXT NOT NULL,
            content TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE checklists (
            id TEXT PRIMARY KEY, card_id TEXT NOT NULL, title TEXT NOT NULL,
            items TEXT NOT NULL DEFAULT '[]'
          )
        ''');
        await db.execute('''
          CREATE TABLE invitations (
            id TEXT PRIMARY KEY, email TEXT NOT NULL, board_id TEXT NOT NULL,
            invited_by TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL, accepted_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE password_reset_tokens (
            id TEXT PRIMARY KEY, user_id TEXT NOT NULL, token TEXT NOT NULL,
            expires_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sprints (
            id TEXT PRIMARY KEY, board_id TEXT NOT NULL, name TEXT NOT NULL,
            goal TEXT, start_date TEXT NOT NULL, end_date TEXT NOT NULL,
            target_hours REAL NOT NULL, status TEXT NOT NULL,
            card_ids TEXT NOT NULL DEFAULT '[]', created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE time_logs (
            id TEXT PRIMARY KEY, card_id TEXT NOT NULL, user_id TEXT NOT NULL,
            start_time TEXT NOT NULL, end_time TEXT, duration_minutes INTEGER NOT NULL DEFAULT 0,
            notes TEXT, is_active INTEGER NOT NULL DEFAULT 0, sprint_id TEXT,
            created_at TEXT NOT NULL, updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE burndown_snapshots (
            id TEXT PRIMARY KEY, sprint_id TEXT NOT NULL, date TEXT NOT NULL,
            remaining_hours REAL NOT NULL, completed_hours REAL NOT NULL,
            total_cards INTEGER NOT NULL, completed_cards INTEGER NOT NULL,
            scope_change_hours REAL NOT NULL DEFAULT 0, created_at TEXT NOT NULL
          )
        ''');
      },
    );

    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert('users', {
      'id': 'local',
      'email': 'local@ollie',
      'name': 'Me',
      'password_hash': '',
      'password_salt': '',
      'created_at': now,
    });
    await db.insert('boards', {
      'id': 'b1',
      'name': 'Legacy board',
      'description': 'old',
      'created_by': 'local',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('columns', {
      'id': 'col1',
      'board_id': 'b1',
      'name': 'To Do',
      'position': 0,
      'color': 0xFF000000,
    });
    await db.insert('sprints', {
      'id': 's1',
      'board_id': 'b1',
      'name': 'Legacy sprint',
      'start_date': now,
      'end_date': now,
      'target_hours': 10,
      'status': 'active',
      'card_ids': '["c2"]',
      'created_at': now,
      'updated_at': now,
    });
    for (final entry in {'c1': 'U', 'c2': 'V'}.entries) {
      await db.insert('cards', {
        'id': entry.key,
        'column_id': 'col1',
        'title': 'Card ${entry.key}',
        'created_by': 'local',
        'rank': entry.value,
        'created_at': now,
        'updated_at': now,
      });
    }
    await db.insert('time_logs', {
      'id': 't1',
      'card_id': 'c1',
      'user_id': 'local',
      'start_time': now,
      'end_time': now,
      'duration_minutes': 90,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('time_logs', {
      'id': 't2',
      'card_id': 'c2',
      'user_id': 'local',
      'start_time': now,
      'end_time': now,
      'duration_minutes': 30,
      'created_at': now,
      'updated_at': now,
    });
    await db.close();
  }

  test('migrates a v1 database without losing core data', () async {
    await createV1Database();

    final db = await DatabaseHelper.instance.database;
    expect(await db.getVersion(), 2);

    final cards = await db.query('cards', orderBy: 'id');
    expect(cards.length, 2);
    expect(cards.first['total_logged_hours'], 1.5);
    expect(cards.last['total_logged_hours'], 0.5);

    // c2 was only listed in the legacy sprint.card_ids blob.
    expect(cards.last['sprint_id'], 's1');

    // Ranks are normalized to the fixed-length format and kept ordered.
    expect((cards.first['rank'] as String).length, 40);
    expect((cards.last['rank'] as String).length, 40);
    expect(
      (cards.first['rank'] as String).compareTo(cards.last['rank'] as String),
      lessThan(0),
    );

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = tables.map((row) => row['name'] as String).toSet();
    expect(names, isNot(contains('users')));
    expect(names, isNot(contains('board_members')));
    expect(names, isNot(contains('labels')));
    expect(names, isNot(contains('comments')));
    expect(names, isNot(contains('invitations')));
    expect(names, isNot(contains('password_reset_tokens')));

    final sprintColumns = await db.rawQuery('PRAGMA table_info(sprints)');
    expect(
      sprintColumns.map((row) => row['name']),
      isNot(contains('card_ids')),
    );

    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    final indexNames = indexes.map((row) => row['name'] as String).toSet();
    expect(indexNames, contains('idx_time_logs_card'));
    expect(indexNames, contains('idx_cards_sprint'));
  });
}
