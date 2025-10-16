import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../config/environment.dart';

/// Singleton service for managing Appwrite authentication
/// Use this instead of AuthGate to work with Navigator 2.0
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final Client _client;
  late final Account _account;

  bool _initialized = false;
  models.User? _currentUser;

  /// Initialize Appwrite client (call once in main.dart)
  void init() {
    if (_initialized) return;

    _client = Client()
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId);

    _account = Account(_client);
    _initialized = true;
  }

  /// Get the Account instance
  Account get account {
    if (!_initialized) {
      throw Exception(
        'AuthService not initialized. Call AuthService().init() first.',
      );
    }
    return _account;
  }

  /// Get the Client instance
  Client get client {
    if (!_initialized) {
      throw Exception(
        'AuthService not initialized. Call AuthService().init() first.',
      );
    }
    return _client;
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      _currentUser = await _account.get();
      return true;
    } catch (e) {
      _currentUser = null;
      return false;
    }
  }

  /// Get current user (null if not authenticated)
  models.User? get currentUser => _currentUser;

  /// Login with email and password
  Future<models.User> login(String email, String password) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      _currentUser = await _account.get();
      return _currentUser!;
    } catch (e) {
      rethrow;
    }
  }

  /// Register new user
  Future<models.User> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Create account
      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Auto-login after registration
      return await login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      _currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout from all devices
  Future<void> logoutAll() async {
    try {
      await _account.deleteSessions();
      _currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password (send recovery email)
  Future<void> resetPassword(String email) async {
    try {
      await _account.createRecovery(
        email: email,
        url: '${Environment.appwritePublicEndpoint}/reset-password',
      );
    } catch (e) {
      rethrow;
    }
  }
}
