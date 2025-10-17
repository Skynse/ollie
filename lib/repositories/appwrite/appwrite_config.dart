import 'package:appwrite/appwrite.dart';
import '../../config/environment.dart';
import 'appwrite_board_repository.dart';
import 'appwrite_user_repository.dart';

/// Appwrite configuration and initialization
class AppwriteConfig {
  static Client? _client;
  static Databases? _databases;
  static Account? _account;

  // Database ID - create this in your Appwrite console
  static const String databaseId =
      '68f0c0100009393371fd'; // Change this to your database ID

  /// Initialize Appwrite client
  static void init() {
    if (_client != null) return; // Already initialized

    _client = Client()
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId);

    _databases = Databases(_client!);
    _account = Account(_client!);
  }

  /// Get Databases instance
  static Databases get databases {
    if (_databases == null) {
      throw Exception(
        'AppwriteConfig not initialized. Call AppwriteConfig.init() first.',
      );
    }
    return _databases!;
  }

  /// Get Account instance
  static Account get account {
    if (_account == null) {
      throw Exception(
        'AppwriteConfig not initialized. Call AppwriteConfig.init() first.',
      );
    }
    return _account!;
  }

  /// Get Client instance
  static Client get client {
    if (_client == null) {
      throw Exception(
        'AppwriteConfig not initialized. Call AppwriteConfig.init() first.',
      );
    }
    return _client!;
  }

  // Repository factory methods
  static AppwriteBoardRepository createBoardRepository() {
    return AppwriteBoardRepository(
      databases: databases,
      databaseId: databaseId,
    );
  }

  static AppwriteUserRepository createUserRepository() {
    return AppwriteUserRepository(
      databases: databases,
      account: account,
      databaseId: databaseId,
    );
  }
}
