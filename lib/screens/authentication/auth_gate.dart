import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/providers/auth_provider.dart';
import 'package:ollie/screens/authentication/modern_auth_screen.dart';

class AuthGate extends ConsumerWidget {
  final Widget home;
  const AuthGate({super.key, required this.home});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.isAuthenticated) {
      return home;
    }

    return const ModernAuthScreen();
  }
}
