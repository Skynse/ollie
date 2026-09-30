import '../../database/database_helper.dart';
import '../board_repository.dart';
import '../sprint_repository.dart';
import '../user_repository.dart';
import 'local_board_repository.dart';
import 'local_sprint_repository.dart';
import 'local_user_repository.dart';

/// Local sqflite configuration and repository factories.
class LocalConfig {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await DatabaseHelper.initFactory();
    await DatabaseHelper.instance.database;
    _initialized = true;
  }

  static LocalBoardRepository createBoardRepository() {
    return LocalBoardRepository();
  }

  static LocalUserRepository createUserRepository() {
    return LocalUserRepository();
  }

  static LocalSprintRepository createSprintRepository() {
    return LocalSprintRepository();
  }

  static BoardRepository get boardRepository => createBoardRepository();
  static UserRepository get userRepository => createUserRepository();
  static SprintRepository get sprintRepository => createSprintRepository();
}
