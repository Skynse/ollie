import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';

/// ChangeNotifier that listens to auth state changes
/// Used to refresh GoRouter without recreating it
class AuthNotifier extends ChangeNotifier {
  final Ref ref;
  AuthState? _previousState;

  AuthNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (_previousState?.isAuthenticated != next.isAuthenticated) {
        notifyListeners();
      }
      _previousState = next;
    });
  }
}

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier(ref);
});
