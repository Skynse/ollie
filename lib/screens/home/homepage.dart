import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';
import 'package:ollie/providers/auth_provider.dart';
import 'package:ollie/providers/boards_provider.dart';
import 'package:ollie/models/board.dart';
import 'package:ollie/screens/home/widgets/home_sidebar.dart';
import 'package:ollie/screens/home/widgets/home_topbar.dart';
import 'package:ollie/screens/home/widgets/board_card.dart';
import 'package:ollie/screens/home/widgets/home_state_widgets.dart';
import 'package:ollie/screens/home/widgets/user_menu_panel.dart';
import 'package:ollie/screens/home/dialogs/create_board_dialog.dart';
import '../../utils/responsive.dart';

/// Trello-like homepage with sidebar navigation
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedView = 'my-projects';
  bool _isUserMenuOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'updated'; // 'name', 'created', 'updated'
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Board> _sortBoards(List<Board> boards) {
    final sorted = List<Board>.from(boards);
    switch (_sortBy) {
      case 'name':
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'created':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'updated':
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    return sorted;
  }

  int _getMyProjectsCount() {
    final boardsState = ref.watch(boardsProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.user?.$id;

    return boardsState.boards
        .where((board) => board.createdBy == userId)
        .length;
  }

  int _getSharedProjectsCount() {
    final boardsState = ref.watch(boardsProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.user?.$id;

    return boardsState.boards
        .where((board) => board.createdBy != userId)
        .length;
  }

  void _showCreateBoardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateBoardDialog(
        onCreateBoard: (name, description) async {
          final board = await ref
              .read(boardsProvider.notifier)
              .createBoard(name: name, description: description);
          return board != null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final isMobile = context.isMobile;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? _buildMobileDrawer(currentUser, authState.isLoading)
          : null,
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar (hide on mobile)
              if (!isMobile)
                HomeSidebar(
                  selectedView: _selectedView,
                  onViewChanged: (view) => setState(() => _selectedView = view),
                  user: currentUser,
                  isLoadingAuth: authState.isLoading,
                  myProjectsCount: _getMyProjectsCount(),
                  sharedProjectsCount: _getSharedProjectsCount(),
                  onUserMenuTap: () =>
                      setState(() => _isUserMenuOpen = !_isUserMenuOpen),
                ),

              // Main content area
              Expanded(child: _buildMainContent()),
            ],
          ),

          // User menu overlay panel (desktop only)
          if (_isUserMenuOpen && !isMobile)
            UserMenuPanel(
              user: currentUser,
              onClose: () => setState(() => _isUserMenuOpen = false),
              onLogout: () {
                ref.read(authProvider.notifier).logout();
                setState(() => _isUserMenuOpen = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(dynamic user, bool isLoadingAuth) {
    return Drawer(
      child: HomeSidebar(
        selectedView: _selectedView,
        onViewChanged: (view) {
          setState(() => _selectedView = view);
          Navigator.pop(context); // Close drawer
        },
        user: user,
        isLoadingAuth: isLoadingAuth,
        myProjectsCount: _getMyProjectsCount(),
        sharedProjectsCount: _getSharedProjectsCount(),
        onUserMenuTap: () {
          Navigator.pop(context); // Close drawer
          _showMobileUserMenu();
        },
      ),
    );
  }

  void _showMobileUserMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.read(authProvider).user?.name ?? 'User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ref.read(authProvider).user?.email ?? '',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [context.surfaceVariantColor, context.backgroundColor],
          stops: const [0.0, 0.3],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          HomeTopBar(
            selectedView: _selectedView,
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
            onSearchClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            sortBy: _sortBy,
            onSortChanged: (value) => setState(() => _sortBy = value),
            isGridView: _isGridView,
            onViewChanged: (isGrid) => setState(() => _isGridView = isGrid),
            onCreateBoard: () => _showCreateBoardDialog(context),
            onMenuTap: context.isMobile
                ? () => _scaffoldKey.currentState?.openDrawer()
                : null,
          ),

          // Content
          Expanded(
            child: _selectedView == 'my-projects'
                ? _buildMyProjectsView()
                : _buildSharedProjectsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProjectsView() {
    final boardsState = ref.watch(boardsProvider);

    if (boardsState.isLoading) {
      return const SkeletonBoardsLoader();
    }

    if (boardsState.errorMessage != null) {
      return BoardsErrorState(
        message: boardsState.errorMessage!,
        onRetry: () => ref.read(boardsProvider.notifier).fetchBoards(),
      );
    }

    final authState = ref.watch(authProvider);
    final userId = authState.user?.$id;

    // Filter to boards created by current user
    var myBoards = boardsState.boards
        .where((board) => board.createdBy == userId)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      myBoards = myBoards.where((board) {
        return board.name.toLowerCase().contains(_searchQuery) ||
            (board.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    if (myBoards.isEmpty) {
      return _searchQuery.isNotEmpty
          ? const NoSearchResultsState()
          : EmptyBoardsState(
              onCreateBoard: () => _showCreateBoardDialog(context),
            );
    }

    final sortedBoards = _sortBoards(myBoards);
    return _isGridView
        ? _buildBoardsGrid(sortedBoards)
        : _buildBoardsList(sortedBoards);
  }

  Widget _buildSharedProjectsView() {
    final boardsState = ref.watch(boardsProvider);

    if (boardsState.isLoading) {
      return const SkeletonBoardsLoader();
    }

    if (boardsState.errorMessage != null) {
      return BoardsErrorState(
        message: boardsState.errorMessage!,
        onRetry: () => ref.read(boardsProvider.notifier).fetchBoards(),
      );
    }

    final authState = ref.watch(authProvider);
    final userId = authState.user?.$id;

    // Filter to boards where user is member but not creator
    var sharedBoards = boardsState.boards
        .where((board) => board.createdBy != userId)
        .toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      sharedBoards = sharedBoards.where((board) {
        return board.name.toLowerCase().contains(_searchQuery) ||
            (board.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    if (sharedBoards.isEmpty) {
      return _searchQuery.isNotEmpty
          ? const NoSearchResultsState()
          : const EmptySharedBoardsState();
    }

    final sortedBoards = _sortBoards(sharedBoards);
    return _isGridView
        ? _buildBoardsGrid(sortedBoards)
        : _buildBoardsList(sortedBoards);
  }

  Widget _buildBoardsGrid(List<Board> boards) {
    final isMobile = context.isMobile;

    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 12 : 32),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isMobile ? double.infinity : 380,
        crossAxisSpacing: isMobile ? 12 : 20,
        mainAxisSpacing: isMobile ? 12 : 20,
        childAspectRatio: isMobile ? 2.5 : 1.8,
      ),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        return BoardCard(board: boards[index], index: index);
      },
    );
  }

  Widget _buildBoardsList(List<Board> boards) {
    final isMobile = context.isMobile;

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 12 : 32),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        return BoardListItem(board: boards[index], index: index);
      },
    );
  }
}
