import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../../config/environment.dart';
import 'appwrite_board_repository.dart';
import 'appwrite_user_repository.dart';
import 'appwrite_sprint_repository.dart';

/// Appwrite configuration and initialization
class AppwriteConfig {
  static Client? _client;
  static Databases? _databases;
  static Account? _account;
  static models.User? _currentUser;

  // Database ID - read from environment configuration
  static String get databaseId => Environment.appwriteDatabaseId;

  // Export app URL from Environment
  static String get appUrl => Environment.appUrl;

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

  static AppwriteSprintRepository createSprintRepository() {
    return AppwriteSprintRepository(
      databases: databases,
      databaseId: databaseId,
    );
  }

  // Auth methods
  static Future<models.User?> isAuthenticated() async {
    try {
      _currentUser = await account.get();
      return _currentUser;
    } catch (e) {
      _currentUser = null;
      return null;
    }
  }

  static models.User? get currentUser => _currentUser;

  static Future<models.User> login(String email, String password) async {
    try {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      _currentUser = await account.get();
      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  static Future<models.User> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      // populate users table with email, blank name, and user id so we can use for email-id lookups

      return await login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
      _currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logoutAll() async {
    try {
      await account.deleteSessions();
      _currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> resetPassword(String email, String redirectUrl) async {
    try {
      await account.createRecovery(email: email, url: redirectUrl);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> completePasswordRecovery({
    required String userId,
    required String secret,
    required String newPassword,
  }) async {
    try {
      await account.updateRecovery(
        userId: userId,
        secret: secret,
        password: newPassword,
      );
    } catch (e) {
      rethrow;
    }
  }
}
