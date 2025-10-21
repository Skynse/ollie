import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home/homepage.dart';
import 'screens/board/board_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/authentication/modern_auth_screen.dart';
import 'repositories/appwrite/appwrite_config.dart';

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
    final authState = ref.watch(authProvider);

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isAuthenticated = authState.isAuthenticated;
        final isLoading = authState.isLoading;
        final isLoginRoute = state.matchedLocation == '/login';

        // Still loading, stay put
        if (isLoading) return null;

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

    return MaterialApp.router(
      title: 'Ollie - Kanban Board',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routerConfig: router,
    );
  }
}
