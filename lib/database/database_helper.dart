import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ollie/config/local_user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Initializes sqflite for the current platform and opens the local database.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;
  static bool _factoryInitialized = false;

  /// Override for tests (e.g. [inMemoryDatabasePath]).
  static String? testDatabasePath;

  static Future<void> initFactory() async {
    if (_factoryInitialized) return;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _factoryInitialized = true;
  }

  static Future<void> resetForTests() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initFactory();
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final path = await _databasePath();
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<String> _databasePath() async {
    if (testDatabasePath != null) {
      return testDatabasePath!;
    }
    if (kIsWeb) {
      return 'ollie.db';
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationDocumentsDirectory();
      return p.join(dir.path, 'ollie.db');
    }
    return p.join(await getDatabasesPath(), 'ollie.db');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        avatar_url TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE password_reset_tokens (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        token TEXT NOT NULL UNIQUE,
        expires_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE boards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_by TEXT NOT NULL,
        column_ids TEXT NOT NULL DEFAULT '[]',
        archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE board_members (
        board_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        PRIMARY KEY (board_id, user_id),
        FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE columns (
        id TEXT PRIMARY KEY,
        board_id TEXT NOT NULL,
        name TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        color INTEGER NOT NULL,
        wip_limit INTEGER,
        card_ids TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        column_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        position INTEGER NOT NULL DEFAULT 0,
        assignee_ids TEXT NOT NULL DEFAULT '[]',
        label_ids TEXT NOT NULL DEFAULT '[]',
        priority TEXT NOT NULL DEFAULT 'low',
        due_date TEXT,
        comment_count INTEGER NOT NULL DEFAULT 0,
        created_by TEXT NOT NULL,
        estimated_hours REAL,
        total_logged_hours REAL NOT NULL DEFAULT 0,
        sprint_id TEXT,
        rank TEXT NOT NULL DEFAULT 'U',
        completed INTEGER NOT NULL DEFAULT 0,
        subtask_count INTEGER NOT NULL DEFAULT 0,
        completed_subtask_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (column_id) REFERENCES columns(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE labels (
        id TEXT PRIMARY KEY,
        board_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE comments (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE checklists (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        title TEXT NOT NULL,
        items TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE invitations (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        board_id TEXT NOT NULL,
        invited_by TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        accepted_at TEXT,
        FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sprints (
        id TEXT PRIMARY KEY,
        board_id TEXT NOT NULL,
        name TEXT NOT NULL,
        goal TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        target_hours REAL NOT NULL,
        status TEXT NOT NULL,
        card_ids TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE time_logs (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        sprint_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE burndown_snapshots (
        id TEXT PRIMARY KEY,
        sprint_id TEXT NOT NULL,
        date TEXT NOT NULL,
        remaining_hours REAL NOT NULL,
        completed_hours REAL NOT NULL,
        total_cards INTEGER NOT NULL,
        completed_cards INTEGER NOT NULL,
        scope_change_hours REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sprint_id) REFERENCES sprints(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_board_members_user ON board_members(user_id)',
    );
    await db.execute('CREATE INDEX idx_columns_board ON columns(board_id)');
    await db.execute('CREATE INDEX idx_cards_column ON cards(column_id)');
    await db.execute('CREATE INDEX idx_comments_card ON comments(card_id)');
    await db.execute(
      'CREATE INDEX idx_sprints_board ON sprints(board_id)',
    );

    await _seedLocalUser(db);
  }

  Future<void> _seedLocalUser(Database db) async {
    await db.insert(
      'users',
      {
        'id': LocalUser.id,
        'email': 'local@ollie',
        'name': LocalUser.name,
        'password_hash': '',
        'password_salt': '',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
