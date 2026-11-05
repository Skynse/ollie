import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'components/ollie_ui/theme.dart';
import 'providers/theme_provider.dart';
import 'repositories/local/local_config.dart';
import 'screens/board/board_screen.dart';
import 'screens/home/homepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  try {
    await LocalConfig.init();
  } catch (error, stack) {
    // A local database failure must never leave the user with a blank page.
    debugPrint('Failed to open the local database: $error\n$stack');
    runApp(StartupErrorApp(error: error));
    return;
  }

  runApp(const ProviderScope(child: OllieApp()));
}

class StartupErrorApp extends StatelessWidget {
  final Object error;

  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ollie - Startup Error',
      debugShowCheckedModeBanner: false,
      theme: OllieTheme.lightTheme,
      darkTheme: OllieTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_outlined, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Ollie could not open its local database',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your boards are stored on this device. Check that the app '
                    'can write to its data directory, then try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: main, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (_, _) => MaterialApp.router(
        title: 'Ollie - Kanban Board',
        debugShowCheckedModeBanner: false,
        theme: OllieTheme.lightTheme,
        darkTheme: OllieTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/boards/:boardId',
        builder: (context, state) {
          final boardId = state.pathParameters['boardId']!;
          return BoardScreen(boardId: boardId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page not found', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to boards'),
            ),
          ],
        ),
      ),
    ),
  );
});
