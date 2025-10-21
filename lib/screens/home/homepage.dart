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

class _HomePageState extends ConsumerState<HomePage> {
  String _selectedView = 'my-projects';
  bool _isUserMenuOpen = false;

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
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
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
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  label: 'Shared with Me',
                  isSelected: _selectedView == 'shared',
                  onTap: () => setState(() => _selectedView = 'shared'),
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
      color: Colors.white,
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
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            _selectedView == 'my-projects' ? 'My Projects' : 'Shared with Me',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _showCreateBoardDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Board'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProjectsView() {
    final boardsState = ref.watch(boardsProvider);

    if (boardsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (boardsState.errorMessage != null) {
      return _buildErrorState(boardsState.errorMessage!);
    }

    final authState = ref.watch(authProvider);
    final userId = authState.user?.$id;

    // Filter to boards created by current user
    final myBoards = boardsState.boards
        .where((board) => board.createdBy == userId)
        .toList();

    if (myBoards.isEmpty) {
      return _buildEmptyState();
    }

    return _buildBoardsGrid(myBoards);
  }

  Widget _buildSharedProjectsView() {
    final boardsState = ref.watch(boardsProvider);

    if (boardsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (boardsState.errorMessage != null) {
      return _buildErrorState(boardsState.errorMessage!);
    }

    final authState = ref.watch(authProvider);
    final userId = authState.user?.$id;

    // Filter to boards where user is member but not creator
    final sharedBoards = boardsState.boards
        .where((board) => board.createdBy != userId)
        .toList();

    if (sharedBoards.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Center(
          child: Text(
            'No boards have been shared with you yet.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return _buildBoardsGrid(sharedBoards);
  }

  Widget _buildBoardsGrid(List<Board> boards) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,

        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.0,
      ),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        return _BoardCard(board: boards[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.dashboard_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No boards yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first board to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateBoardDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Board'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => ref.read(boardsProvider.notifier).fetchBoards(),
            child: const Text('Retry'),
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

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
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
        selected: isSelected,
        selectedTileColor: Colors.blue.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: onTap,
      ),
    );
  }
}

/// Board card widget - compact Trello-style card
class _BoardCard extends StatelessWidget {
  final Board board;

  const _BoardCard({required this.board});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          context.push('/boards/${board.id}');
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Board name
              Text(
                board.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Board description (if exists)
              if (board.description != null && board.description!.isNotEmpty)
                Text(
                  board.description!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              // Bottom row: member count
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${board.memberIds.length} ${board.memberIds.length == 1 ? 'member' : 'members'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
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
