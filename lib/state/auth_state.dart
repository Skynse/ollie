import 'package:appwrite/models.dart' as models;

/// Represents the authentication state of the app
/// Immutable - use copyWith to create new states
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final models.User? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = true,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  /// Initial loading state
  const AuthState.loading()
    : isLoading = true,
      isAuthenticated = false,
      user = null,
      errorMessage = null;

  /// Authenticated state
  const AuthState.authenticated(this.user)
    : isLoading = false,
      isAuthenticated = true,
      errorMessage = null;

  /// Unauthenticated state
  const AuthState.unauthenticated()
    : isLoading = false,
      isAuthenticated = false,
      user = null,
      errorMessage = null;

  /// Error state
  const AuthState.error(this.errorMessage)
    : isLoading = false,
      isAuthenticated = false,
      user = null;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    models.User? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
