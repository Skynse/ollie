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

/// Trello-like homepage with sidebar navigation
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
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

          // User menu overlay panel
          if (_isUserMenuOpen)
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
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.8,
      ),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        return BoardCard(board: boards[index], index: index);
      },
    );
  }

  Widget _buildBoardsList(List<Board> boards) {
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        return BoardListItem(board: boards[index], index: index);
      },
    );
  }
}
