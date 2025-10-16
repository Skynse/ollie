import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ollie/services/auth_api.dart';
import 'screens/home/homepage.dart';
import 'providers/auth_provider.dart';
import 'screens/authentication/modern_auth_screen.dart';
import 'repositories/appwrite/appwrite_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Appwrite (for both auth and repositories)
  AuthApi().init();
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
          path: '/projects/:projectId',
          builder: (context, state) {
            final projectId = state.pathParameters['projectId']!;
            return const Placeholder(); // ProjectBoardsScreen
          },
        ),
        GoRoute(
          path: '/projects/:projectId/boards/:boardId',
          builder: (context, state) {
            final projectId = state.pathParameters['projectId']!;
            final boardId = state.pathParameters['boardId']!;
            return const Placeholder(); // BoardScreen
          },
        ),
        GoRoute(
          path: '/projects/:projectId/boards/:boardId/cards/:cardId',
          builder: (context, state) {
            final projectId = state.pathParameters['projectId']!;
            final boardId = state.pathParameters['boardId']!;
            final cardId = state.pathParameters['cardId']!;
            return const Placeholder(); // CardDetailsScreen
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
