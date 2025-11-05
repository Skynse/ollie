import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home/homepage.dart';
import 'screens/board/board_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/authentication/modern_auth_screen.dart';
import 'screens/authentication/password_reset_screen.dart';
import 'repositories/appwrite/appwrite_config.dart';
import 'components/ollie_ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Appwrite (for both auth and repositories)
  AppwriteConfig.init();

  runApp(const ProviderScope(child: OllieApp()));
}

class OllieApp extends ConsumerWidget {
  const OllieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeModeAsync = ref.watch(themeModeProvider);

    return themeModeAsync.when(
      data: (themeMode) => MaterialApp.router(
        title: 'Ollie - Kanban Board',
        debugShowCheckedModeBanner: false,
        theme: OllieTheme.lightTheme,
        darkTheme: OllieTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
      ),
      loading: () => MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (_, __) => MaterialApp.router(
        title: 'Ollie - Kanban Board',
        debugShowCheckedModeBanner: false,
        theme: OllieTheme.lightTheme,
        darkTheme: OllieTheme.darkTheme,
        themeMode: ThemeMode.system, // Fallback to system
        routerConfig: router,
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isLoginRoute = state.matchedLocation == '/login';
      final isResetRoute = state.matchedLocation.startsWith('/reset-password');

      // Still loading, stay put
      if (isLoading) return null;

      // Allow password reset page without authentication
      if (isResetRoute) return null;

      // Not authenticated, redirect to login
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // Authenticated but on login page, redirect to home
      if (isAuthenticated && isLoginRoute) {
        return '/';
      }

      // All good, continue
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const ModernAuthScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final userId = state.uri.queryParameters['userId'];
          final secret = state.uri.queryParameters['secret'];

          // If missing parameters, redirect to login
          if (userId == null || secret == null) {
            Future.microtask(() => context.go('/login'));
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return PasswordResetScreen(userId: userId, secret: secret);
        },
      ),
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/boards/:boardId',
        builder: (context, state) {
          final boardId = state.pathParameters['boardId']!;
          return BoardScreen(boardId: boardId);
        },
      ),
    ],
  );
});
