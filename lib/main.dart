import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home/homepage.dart';
import 'screens/board/board_screen.dart';
import 'providers/theme_provider.dart';
import 'repositories/local/local_config.dart';
import 'components/ollie_ui/theme.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalConfig.init();
  usePathUrlStrategy();
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
  );
});
