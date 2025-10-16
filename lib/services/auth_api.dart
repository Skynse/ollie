import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../config/environment.dart';

class AuthApi {
  static final AuthApi _instance = AuthApi._internal();
  factory AuthApi() => _instance;
  AuthApi._internal();

  late final Client _client;
  late final Account _account;

  bool _initialized = false;
  models.User? _currentUser;

  void init() {
    if (_initialized) return;

    _client = Client()
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId);

    _account = Account(_client);
    _initialized = true;
  }

  Account get account {
    if (!_initialized) {
      throw Exception('AuthApi not initialized. Call AuthApi().init() first.');
    }
    return _account;
  }

  Client get client {
    if (!_initialized) {
      throw Exception('AuthApi not initialized. Call AuthApi().init() first.');
    }
    return _client;
  }

  Future<models.User?> isAuthenticated() async {
    try {
      _currentUser = await _account.get();
      return _currentUser;
    } catch (e) {
      _currentUser = null;
      return null;
    }
  }

  models.User? get currentUser => _currentUser;

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

  Future<models.User> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return await login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      _currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logoutAll() async {
    try {
      await _account.deleteSessions();
      _currentUser = null;
    } catch (e) {
      rethrow;
    }
  }

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
