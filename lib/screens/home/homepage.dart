import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/boards_provider.dart';
import '../../models/board.dart';
import '../../components/ollie_ui/ollie_dialog.dart';
import '../../components/ollie_ui/ollie_textfield.dart';
import '../../components/ollie_ui/ollie_button.dart';
import '../../components/ollie_ui/ollie_toast.dart';

/// Trello-like homepage with sidebar navigation
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    // Read auth state from provider - NO additional fetching
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              _buildSidebar(context, currentUser, authState.isLoading),

              // Main content area
              Expanded(child: _buildMainContent()),
            ],
          ),

          // User menu overlay panel
          if (_isUserMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isUserMenuOpen = false),
              child: Container(
                color: Colors.black38,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping panel
                    child: _UserMenuPanel(
                      user: currentUser,
                      onClose: () => setState(() => _isUserMenuOpen = false),
                      onLogout: () {
                        ref.read(authProvider.notifier).logout();
                        setState(() => _isUserMenuOpen = false);
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, dynamic user, bool isLoadingAuth) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ollie',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'My Projects',
                  isSelected: _selectedView == 'my-projects',
                  onTap: () => setState(() => _selectedView = 'my-projects'),
                  count: _getMyProjectsCount(),
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  label: 'Shared with Me',
                  isSelected: _selectedView == 'shared',
                  onTap: () => setState(() => _selectedView = 'shared'),
                  count: _getSharedProjectsCount(),
                ),
              ],
            ),
          ),

          // User menu at bottom
          const Divider(height: 1),
          InkWell(
            onTap: () => setState(() => _isUserMenuOpen = !_isUserMenuOpen),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoadingAuth
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 18,
                          child: Text(
                            user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User Name',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? 'user@example.com',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.more_horiz, color: Colors.grey.shade600),
                      ],
                    ),
            ),
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
          colors: [const Color(0xFFF8F9FA), Colors.white],
          stops: const [0.0, 0.3],
        ),
      ),
      child: Column(
        children: [
          // Top bar
          _buildTopBar(),

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

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title
          Text(
            _selectedView == 'my-projects' ? 'My Projects' : 'Shared with Me',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 24),

          // Search bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search boards...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const Spacer(),

          // View toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _ViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                ),
                _ViewToggleButton(
                  icon: Icons.view_list_rounded,
                  isSelected: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Sort dropdown
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'updated',
                child: Row(
                  children: [
                    Icon(Icons.update, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    const Text('Last Updated'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'created',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 12),
                    const Text('Date Created'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 12),
                    const Text('Name (A-Z)'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _sortBy == 'updated'
                        ? 'Updated'
                        : _sortBy == 'created'
                        ? 'Created'
                        : 'Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // New Board button
          FilledButton.icon(
            onPressed: () => _showCreateBoardDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('New Board'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProjectsView() {
    final boardsState = ref.watch(boardsProvider);

    if (boardsState.isLoading) {
      return _buildSkeletonLoader();
    }

    if (boardsState.errorMessage != null) {
      return _buildErrorState(boardsState.errorMessage!);
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
          ? _buildNoSearchResults()
          : _buildEmptyState();
    }

    final sortedBoards = _sortBoards(myBoards);
    return _isGridView
        ? _buildBoardsGrid(sortedBoards)
        : _buildBoardsList(sortedBoards);
  }

  Widget _buildSharedProjectsView() {
    final boardsState = ref.watch(boardsProvider);

    if (boardsState.isLoading) {
      return _buildSkeletonLoader();
    }

    if (boardsState.errorMessage != null) {
      return _buildErrorState(boardsState.errorMessage!);
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
      if (_searchQuery.isNotEmpty) {
        return _buildNoSearchResults();
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.people_outline,
                size: 40,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No shared boards yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Boards shared with you will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
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
        return _BoardCard(board: boards[index], index: index);
      },
    );
  }

  Widget _buildBoardsList(List<Board> boards) {
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        return _BoardListItem(board: boards[index], index: index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.dashboard_outlined,
              size: 56,
              color: Colors.blue.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No boards yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first board to start organizing your work',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _showCreateBoardDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Create Your First Board'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No boards found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _SkeletonBoardCard();
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => ref.read(boardsProvider.notifier).fetchBoards(),
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Try Again'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateBoardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateBoardDialog(
        onCreateBoard: (name, description) async {
          final board = await ref
              .read(boardsProvider.notifier)
              .createBoard(name: name, description: description);
          return board != null;
        },
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
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
}

/// Modern user menu panel that slides up from bottom-left
class _UserMenuPanel extends StatelessWidget {
  final dynamic user;
  final VoidCallback onClose;
  final VoidCallback onLogout;

  const _UserMenuPanel({
    required this.user,
    required this.onClose,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(left: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with user info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  radius: 24,
                  child: Text(
                    user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'user@example.com',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // _UserMenuItem(
                //   icon: Icons.person_outline,
                //   label: 'Profile',
                //   onTap: () {
                //     onClose();
                //     // TODO: Navigate to profile
                //   },
                // ),
                // _UserMenuItem(
                //   icon: Icons.settings_outlined,
                //   label: 'Settings',
                //   onTap: () {
                //     onClose();
                //     // TODO: Navigate to settings
                //   },
                // ),
                // _UserMenuItem(
                //   icon: Icons.help_outline,
                //   label: 'Help & Support',
                //   onTap: () {
                //     onClose();
                //     // TODO: Navigate to help
                //   },
                // ),
                const Divider(height: 1),
                _UserMenuItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  isDestructive: true,
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual menu item in user panel
class _UserMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _UserMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : Colors.grey.shade800;
    final iconColor = isDestructive
        ? Colors.red.shade600
        : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sidebar navigation item
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
          ),
        ),
        trailing: count != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.shade600
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor: Colors.blue.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: onTap,
      ),
    );
  }
}

/// Board card widget - enhanced with hover effects and colored headers
class _BoardCard extends StatefulWidget {
  final Board board;
  final int index;

  const _BoardCard({required this.board, required this.index});

  @override
  State<_BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<_BoardCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Color palette for board headers
  static const List<Color> boardColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFF6366F1), // Indigo
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _boardColor => boardColors[widget.index % boardColors.length];

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? _boardColor.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? _boardColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _isHovered ? 20 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/boards/${widget.board.id}'),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colored header bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_boardColor, _boardColor.withOpacity(0.7)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                  ),

                  // Card content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Board name
                              Text(
                                widget.board.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Board description (if exists)
                              if (widget.board.description != null &&
                                  widget.board.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  widget.board.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),

                          // Bottom section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Last updated timestamp
                              Row(
                                children: [
                                  Icon(
                                    Icons.update,
                                    size: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getTimeAgo(widget.board.updatedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Member count and arrow
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _boardColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 16,
                                          color: _boardColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${widget.board.memberIds.length}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _boardColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_isHovered)
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                      color: _boardColor,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading card for better UX
class _SkeletonBoardCard extends StatefulWidget {
  @override
  State<_SkeletonBoardCard> createState() => _SkeletonBoardCardState();
}

class _SkeletonBoardCardState extends State<_SkeletonBoardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton header bar
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200.withOpacity(_animation.value),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
              );
            },
          ),

          // Skeleton content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skeleton title
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Container(
                            height: 20,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200.withOpacity(
                                _animation.value,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Skeleton description lines
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200.withOpacity(
                                _animation.value,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Container(
                            height: 14,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200.withOpacity(
                                _animation.value,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Skeleton member badge
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        height: 28,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200.withOpacity(
                            _animation.value,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Create board dialog - only triggers API call on button click
class _CreateBoardDialog extends StatefulWidget {
  final Future<bool> Function(String name, String? description) onCreateBoard;

  const _CreateBoardDialog({required this.onCreateBoard});

  @override
  State<_CreateBoardDialog> createState() => _CreateBoardDialogState();
}

class _CreateBoardDialogState extends State<_CreateBoardDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_nameController.text.trim().isEmpty) {
      OllieToast.info(context, 'Please enter a board name');
      return;
    }

    setState(() => _isCreating = true);

    final success = await widget.onCreateBoard(
      _nameController.text.trim(),
      _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    if (mounted) {
      setState(() => _isCreating = false);
      if (success) {
        Navigator.pop(context);
        OllieToast.success(context, 'Board created!');
      } else {
        OllieToast.error(context, 'Failed to create board');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OllieDialog(
      title: 'Create Board',
      width: 480,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Board name input
          OllieTextfield.simple(
            label: 'Board Name',
            hint: 'e.g., Sprint Planning',
            controller: _nameController,
            enabled: !_isCreating,
          ),

          const SizedBox(height: 20),

          // Description input
          OllieTextfield.simple(
            label: 'Description (optional)',
            hint: 'What will you track in this board?',
            controller: _descriptionController,
            enabled: !_isCreating,
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        // Cancel button
        OllieButton.text(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
          disabled: _isCreating,
          width: null,
        ),

        // Create button
        OllieButton(
          text: 'Create Board',
          onPressed: _handleCreate,
          loading: _isCreating,
          width: null,
        ),
      ],
    );
  }
}

/// View toggle button for switching between grid and list views
class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

/// Board list item widget - for list view
class _BoardListItem extends StatefulWidget {
  final Board board;
  final int index;

  const _BoardListItem({required this.board, required this.index});

  @override
  State<_BoardListItem> createState() => _BoardListItemState();
}

class _BoardListItemState extends State<_BoardListItem> {
  bool _isHovered = false;

  // Color palette for board headers
  static const List<Color> boardColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFF6366F1), // Indigo
  ];

  Color get _boardColor => boardColors[widget.index % boardColors.length];

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? _boardColor.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? _boardColor.withOpacity(0.1)
                    : Colors.black.withOpacity(0.02),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/boards/${widget.board.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Color indicator
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_boardColor, _boardColor.withOpacity(0.6)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Board info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.board.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          if (widget.board.description != null &&
                              widget.board.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.board.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.update,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Updated ${_getTimeAgo(widget.board.updatedAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Member count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _boardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 18,
                            color: _boardColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.board.memberIds.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _boardColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Arrow icon
                    if (_isHovered)
                      Icon(Icons.arrow_forward, size: 20, color: _boardColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
