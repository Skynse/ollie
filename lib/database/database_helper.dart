import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../algos/lexorank.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Initializes sqflite for the current platform and opens the local database.
///
/// Ollie is a local-first, single-user app: the database owns every board,
/// column, card, sprint, checklist, time log and burndown snapshot. There are
/// no accounts, members, invitations, labels or comments.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  /// Version 2 is the local-only schema. Version 1 was the Appwrite port and
  /// contained users, members, invites, labels and comments.
  static const int schemaVersion = 2;

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
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Migrations rebuild tables, which requires foreign keys to be off.
        final current = await db.getVersion();
        if (current != 0 && current < schemaVersion) {
          await db.execute('PRAGMA foreign_keys = OFF');
        } else {
          await db.execute('PRAGMA foreign_keys = ON');
        }
      },
      onOpen: (db) async {
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
    await _createSchema(db, '');
    await _createIndexes(db, '');
  }

  /// Creates the current schema. [suffix] is used by the migration to build
  /// replacement tables before the legacy ones are dropped.
  Future<void> _createSchema(Database db, String suffix) async {
    await db.execute('''
      CREATE TABLE boards$suffix (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE columns$suffix (
        id TEXT PRIMARY KEY,
        board_id TEXT NOT NULL,
        name TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        color INTEGER NOT NULL,
        wip_limit INTEGER,
        FOREIGN KEY (board_id) REFERENCES boards$suffix(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cards$suffix (
        id TEXT PRIMARY KEY,
        column_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL DEFAULT 'low',
        due_date TEXT,
        estimated_hours REAL,
        total_logged_hours REAL NOT NULL DEFAULT 0,
        sprint_id TEXT,
        rank TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        subtask_count INTEGER NOT NULL DEFAULT 0,
        completed_subtask_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (column_id) REFERENCES columns$suffix(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE checklists$suffix (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        title TEXT NOT NULL,
        items TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (card_id) REFERENCES cards$suffix(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sprints$suffix (
        id TEXT PRIMARY KEY,
        board_id TEXT NOT NULL,
        name TEXT NOT NULL,
        goal TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        target_hours REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (board_id) REFERENCES boards$suffix(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE time_logs$suffix (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 0,
        sprint_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards$suffix(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE burndown_snapshots$suffix (
        id TEXT PRIMARY KEY,
        sprint_id TEXT NOT NULL,
        date TEXT NOT NULL,
        remaining_hours REAL NOT NULL,
        completed_hours REAL NOT NULL,
        total_cards INTEGER NOT NULL,
        completed_cards INTEGER NOT NULL,
        scope_change_hours REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sprint_id) REFERENCES sprints$suffix(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createIndexes(Database db, String suffix) async {
    await db.execute(
      'CREATE INDEX idx_columns_board$suffix ON columns$suffix(board_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cards_column$suffix ON cards$suffix(column_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cards_sprint$suffix ON cards$suffix(sprint_id)',
    );
    await db.execute(
      'CREATE INDEX idx_checklists_card$suffix ON checklists$suffix(card_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sprints_board$suffix ON sprints$suffix(board_id)',
    );
    await db.execute(
      'CREATE INDEX idx_time_logs_card$suffix ON time_logs$suffix(card_id)',
    );
    await db.execute(
      'CREATE INDEX idx_time_logs_sprint$suffix ON time_logs$suffix(sprint_id)',
    );
    await db.execute(
      'CREATE INDEX idx_burndown_sprint$suffix '
      'ON burndown_snapshots$suffix(sprint_id)',
    );
  }

  /// Migrates the Appwrite-era v1 database in place.
  ///
  /// Core local data (boards, columns, cards, sprints, checklists, time logs
  /// and burndown snapshots) is preserved. Collaboration-only columns and
  /// tables are dropped. Sprint membership stored in `sprints.card_ids` is
  /// copied into `cards.sprint_id` first, and card totals are recomputed from
  /// the time log table.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _v1ToV2(db);
    }
  }

  Future<void> _v1ToV2(Database db) async {
    // Capture sprint membership before the legacy sprints table is dropped.
    final legacySprintCards = <String, List<String>>{};
    try {
      final rows = await db.query('sprints', columns: ['id', 'card_ids']);
      for (final row in rows) {
        final id = row['id'] as String?;
        final raw = row['card_ids'];
        if (id == null) continue;
        if (raw is String && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              legacySprintCards[id] = decoded
                  .map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          } catch (_) {
            // Ignore malformed legacy JSON; card.sprint_id still wins.
          }
        }
      }
    } catch (_) {
      // A partially migrated database may not have the legacy column.
    }

    await _createSchema(db, '_v2');

    await db.execute('''
      INSERT INTO boards_v2 (id, name, description, archived, created_at, updated_at)
      SELECT id, name, description, archived, created_at, updated_at FROM boards
    ''');

    await db.execute('''
      INSERT INTO columns_v2 (id, board_id, name, position, color, wip_limit)
      SELECT id, board_id, name, position, color, wip_limit FROM columns
    ''');

    await db.execute('''
      INSERT INTO cards_v2 (
        id, column_id, title, description, priority, due_date, estimated_hours,
        total_logged_hours, sprint_id, rank, completed, subtask_count,
        completed_subtask_count, created_at, updated_at
      )
      SELECT
        id, column_id, title, description, priority, due_date, estimated_hours,
        total_logged_hours, sprint_id, rank, completed, subtask_count,
        completed_subtask_count, created_at, updated_at
      FROM cards
    ''');

    await db.execute('''
      INSERT INTO checklists_v2 (id, card_id, title, items)
      SELECT id, card_id, title, items FROM checklists
    ''');

    await db.execute('''
      INSERT INTO sprints_v2 (
        id, board_id, name, goal, start_date, end_date, target_hours, status,
        created_at, updated_at
      )
      SELECT id, board_id, name, goal, start_date, end_date, target_hours,
        status, created_at, updated_at
      FROM sprints
    ''');

    await db.execute('''
      INSERT INTO time_logs_v2 (
        id, card_id, start_time, end_time, duration_minutes, notes, is_active,
        sprint_id, created_at, updated_at
      )
      SELECT id, card_id, start_time, end_time, duration_minutes, notes,
        is_active, sprint_id, created_at, updated_at
      FROM time_logs
    ''');

    await db.execute('''
      INSERT INTO burndown_snapshots_v2 (
        id, sprint_id, date, remaining_hours, completed_hours, total_cards,
        completed_cards, scope_change_hours, created_at
      )
      SELECT id, sprint_id, date, remaining_hours, completed_hours, total_cards,
        completed_cards, scope_change_hours, created_at
      FROM burndown_snapshots
    ''');

    // Backfill cards that only existed in the legacy sprint's card_ids array.
    for (final entry in legacySprintCards.entries) {
      if (entry.value.isEmpty) continue;
      final placeholders = List.filled(entry.value.length, '?').join(',');
      await db.rawUpdate(
        'UPDATE cards_v2 SET sprint_id = ? '
        'WHERE id IN ($placeholders) AND (sprint_id IS NULL OR sprint_id = \'\')',
        [entry.key, ...entry.value],
      );
    }

    // Appwrite used empty strings for optional values; normalize them.
    await db.execute(
      "UPDATE cards_v2 SET sprint_id = NULL WHERE sprint_id = ''",
    );
    await db.execute("UPDATE cards_v2 SET due_date = NULL WHERE due_date = ''");
    await db.execute(
      "UPDATE time_logs_v2 SET sprint_id = NULL WHERE sprint_id = ''",
    );
    await db.execute("UPDATE sprints_v2 SET goal = NULL WHERE goal = ''");

    // Recompute the denormalized card totals from the source of truth.
    await db.execute('''
      UPDATE cards_v2 SET total_logged_hours = COALESCE(
        (SELECT SUM(duration_minutes) / 60.0 FROM time_logs_v2
         WHERE time_logs_v2.card_id = cards_v2.id),
        0
      )
    ''');

    for (final table in [
      'burndown_snapshots',
      'time_logs',
      'checklists',
      'cards',
      'columns',
      'sprints',
      'boards',
      'users',
      'board_members',
      'labels',
      'comments',
      'invitations',
      'password_reset_tokens',
    ]) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }

    for (final table in [
      'boards',
      'columns',
      'cards',
      'checklists',
      'sprints',
      'time_logs',
      'burndown_snapshots',
    ]) {
      await db.execute('ALTER TABLE ${table}_v2 RENAME TO $table');
    }

    // Normalize legacy variable-length ranks to the fixed-length format used
    // by the current LexoRank implementation. This also repairs duplicates.
    final columns = await db.query('columns', columns: ['id']);
    for (final column in columns) {
      final columnId = column['id'] as String;
      final cards = await db.query(
        'cards',
        columns: ['id'],
        where: 'column_id = ?',
        whereArgs: [columnId],
        orderBy: 'rank ASC',
      );
      if (cards.isEmpty) continue;
      final ranks = LexoRank.distribute(cards.length);
      for (var i = 0; i < cards.length; i++) {
        await db.update(
          'cards',
          {'rank': ranks[i]},
          where: 'id = ?',
          whereArgs: [cards[i]['id']],
        );
      }
    }

    await _createIndexes(db, '');
  }
}
