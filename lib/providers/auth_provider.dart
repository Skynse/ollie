import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ollie/repositories/appwrite/appwrite_config.dart';
import 'package:ollie/state/auth_state.dart';

final authProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final user = await AppwriteConfig.isAuthenticated();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await AppwriteConfig.login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await AppwriteConfig.register(email, password, name);

      // Create user record in the users collection
      final databases = Databases(AppwriteConfig.client);
      await databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'users',
        documentId: user.$id, // Use Appwrite account ID as document ID
        data: {'email': email, 'name': name},
      );

      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await AppwriteConfig.logout();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final redirectUrl = '${AppwriteConfig.appUrl}/reset-password';
      await AppwriteConfig.resetPassword(email, redirectUrl);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> checkAuthStatus() async {
    await _checkAuthStatus();
  }
}
