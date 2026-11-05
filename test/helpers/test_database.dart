import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/algos/lexorank.dart';
import 'package:ollie/database/database_helper.dart';
import 'package:ollie/models/board.dart';
import 'package:ollie/models/board_column.dart';
import 'package:ollie/models/card.dart';
import 'package:ollie/models/priority.dart';
import 'package:ollie/models/sprint.dart';
import 'package:ollie/repositories/local/local_board_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

int _testDbCounter = 0;
bool _ffiInitialized = false;
Future<void> _serial = Future.value();
final _tempDbFiles = <String>[];

Future<T> runSerial<T>(Future<T> Function() fn) {
  final result = _serial.then((_) => fn());
  _serial = result.then((_) {}, onError: (_) {});
  return result;
}

Future<LocalBoardRepository> setUpTestDatabase() {
  return runSerial(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    if (!_ffiInitialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }

    await DatabaseHelper.resetForTests();

    final dbPath =
        '${Directory.systemTemp.path}/ollie_test_${pid}_${_testDbCounter++}.db';
    _tempDbFiles.add(dbPath);
    if (File(dbPath).existsSync()) {
      await deleteDatabase(dbPath);
    }
    DatabaseHelper.testDatabasePath = dbPath;

    await DatabaseHelper.instance.database;
    return LocalBoardRepository();
  });
}

Future<void> tearDownTestDatabase() {
  return runSerial(() async {
    await DatabaseHelper.resetForTests();
    for (final path in _tempDbFiles) {
      if (File(path).existsSync()) {
        await deleteDatabase(path);
      }
    }
    _tempDbFiles.clear();
  });
}

Future<void> waitForBoardsIdle(
  dynamic container,
  dynamic boardsProvider,
) async {
  for (var i = 0; i < 50; i++) {
    if (!container.read(boardsProvider).isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Board testBoard({String name = 'Test Board', bool archived = false}) {
  final now = DateTime.now();
  return Board(
    id: '',
    name: name,
    description: 'A test board',
    archived: archived,
    createdAt: now,
    updatedAt: now,
  );
}

BoardColumn testColumn({
  required String boardId,
  String name = 'To Do',
  int position = 0,
  int? wipLimit,
}) {
  return BoardColumn(
    id: '',
    boardId: boardId,
    name: name,
    position: position,
    color: 0xFF9E9E9E,
    wipLimit: wipLimit,
  );
}

Card testCard({
  required String columnId,
  String title = 'Test card',
  String? rank,
  String? sprintId,
}) {
  final now = DateTime.now();
  return Card(
    id: '',
    columnId: columnId,
    title: title,
    priority: Priority.medium,
    rank: rank ?? LexoRank.middle('', ''),
    sprintId: sprintId,
    completed: false,
    createdAt: now,
    updatedAt: now,
  );
}

Sprint testSprint({
  required String boardId,
  String name = 'Sprint 1',
  SprintStatus status = SprintStatus.planning,
}) {
  final now = DateTime.now();
  return Sprint(
    id: '',
    boardId: boardId,
    name: name,
    startDate: now,
    endDate: now.add(const Duration(days: 14)),
    targetHours: 40,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

Future<({String boardId, String columnId})> seedBoardWithColumn(
  LocalBoardRepository repo,
) async {
  final board = await repo.createBoard(testBoard());
  final column = await repo.createColumn(testColumn(boardId: board.id));
  return (boardId: board.id, columnId: column.id);
}
