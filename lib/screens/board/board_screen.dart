import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';
import '../../providers/board_provider.dart';
import '../../providers/boards_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/sprint_provider.dart';
import '../../models/board.dart';
import '../../models/sprint.dart';
import '../../components/components.dart';
import '../../components/board_menu_overlay.dart';
import '../../utils/responsive.dart';
import '../../widgets/multiplayer_cursors.dart';
import '../home/dialogs/archive_board_dialog.dart';

/// Main kanban board screen showing columns and cards
class BoardScreen extends ConsumerStatefulWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final boardState = ref.watch(boardNotifierProvider(widget.boardId));

    return Scaffold(
      key: _scaffoldKey,
      body: boardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (state) => _buildBoardView(state),
      ),
    );
  }

  Widget _buildBoardDrawer() {
    final boardState = ref.watch(boardNotifierProvider(widget.boardId));
    final board = boardState.value?.board;
    final activeSprint = ref.watch(sprintNotifierProvider(widget.boardId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menu Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(
              bottom: BorderSide(color: context.borderColor, width: 1),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    board?.name ?? 'Board Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () {
                      BoardMenuOverlay.hide();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Board Management',
                style: TextStyle(
                  fontSize: 13,
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),

        // Active Sprint Status Card
        if (activeSprint != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: activeSprint.status == SprintStatus.active
                            ? context.successColor.withOpacity(0.1)
                            : context.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: activeSprint.status == SprintStatus.active
                              ? context.successColor.withOpacity(0.3)
                              : context.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        activeSprint.status == SprintStatus.active
                            ? 'ACTIVE'
                            : 'PLANNING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: activeSprint.status == SprintStatus.active
                              ? context.successColor
                              : context.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  activeSprint.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: context.secondaryTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${activeSprint.daysRemaining} days remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.assignment,
                      size: 14,
                      color: context.secondaryTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${activeSprint.cardIds.length} cards',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Menu Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // Sprints Section - Moved to top
                _buildDrawerSection('Sprint'),
                _buildDrawerTile(
                  icon: Icons.view_list,
                  title: 'Manage Sprints',
                  onTap: () {
                    _showSprintManagementDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.add,
                  title: 'Create Sprint',
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) =>
                          CreateSprintDialog(boardId: widget.boardId),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Board Section
                _buildDrawerSection('Board'),
                _buildDrawerTile(
                  icon: Icons.edit,
                  title: 'Edit Board',
                  onTap: () {
                    _showEditBoardDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.view_column,
                  title: 'Manage Columns',
                  onTap: () {
                    _showManageColumnsDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  onTap: () {
                    _showBoardAnalyticsDialog();
                  },
                ),

                const SizedBox(height: 16),

                // More Section
                _buildDrawerSection('More'),
                _buildDrawerTile(
                  icon: Icons.file_download,
                  title: 'Export',
                  onTap: () {
                    _showExportBoardDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.archive,
                  title: 'Archive',
                  onTap: () {
                    _showArchiveBoardDialog();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.secondaryTextColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: iconColor ?? Theme.of(context).listTileTheme.textColor,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).listTileTheme.textColor,
          ),
        ),
        onTap: () {
          BoardMenuOverlay.hide();
          onTap();
        },
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).listTileTheme.textColor,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // Dialog methods with actual functionality
  void _showEditBoardDialog() {
    final boardState = ref.read(boardNotifierProvider(widget.boardId));
    if (!boardState.hasValue) return;
    final board = boardState.value!.board;

    showDialog(
      context: context,
      builder: (context) => EditBoardDialog(
        board: board,
        onSave: (name, description) async {
          try {
            final repository = ref.read(boardRepositoryProvider);
            final updatedBoard = board.copyWith(
              name: name,
              description: description,
              updatedAt: DateTime.now(),
            );
            await repository.updateBoard(updatedBoard);
            return true;
          } catch (e) {
            return false;
          }
        },
      ),
    );
  }

  void _showBoardThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Board Theme'),
        content: const Text(
          'Theme customization will allow you to change colors, '
          'backgrounds, and visual styles for your board.\n\n'
          'This feature is coming in a future update.',
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

  void _showArchiveBoardDialog() {
    final boardState = ref.read(boardNotifierProvider(widget.boardId));
    if (!boardState.hasValue) return;
    final board = boardState.value!.board;

    showDialog(
      context: context,
      builder: (context) => ArchiveBoardDialog(
        boardName: board.name,
        onConfirm: () async {
          final goRouter = GoRouter.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          BoardMenuOverlay.hide();

          try {
            await ref.read(boardsProvider.notifier).archiveBoard(board.id);

            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Board archived successfully')),
            );
            // Navigate back to homepage
            goRouter.go('/');
          } catch (e) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Failed to archive board')),
            );
          }
        },
      ),
    );
  }

  void _showManageMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => ManageMembersDialog(
        boardId: widget.boardId,
        onRemoveMember: (userId) async {
          final repository = ref.read(boardRepositoryProvider);
          await repository.removeMember(widget.boardId, userId);
          // Smoothly refresh just the board data (not the entire page)
          await ref
              .read(boardNotifierProvider(widget.boardId).notifier)
              .refreshBoard();
        },
        onInviteMore: () => _showInviteMemberDialog(),
      ),
    );
  }

  void _showRolesPermissionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Roles & Permissions'),
        content: const Text(
          'Roles & Permissions will allow you to:\n\n'
          '• Assign different roles (Owner, Admin, Member, Viewer)\n'
          '• Control who can edit cards and columns\n'
          '• Manage board settings access\n'
          '• Set custom permissions\n\n'
          'This feature is coming in a future update.',
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

  void _showManageColumnsDialog() {
    final boardState = ref.read(boardNotifierProvider(widget.boardId));
    if (!boardState.hasValue) return;
    final columns = boardState.value!.columns;

    showDialog(
      context: context,
      builder: (context) => ManageColumnsDialog(
        columns: columns,
        onDeleteColumn: (columnId) async {
          await ref
              .read(boardNotifierProvider(widget.boardId).notifier)
              .deleteColumn(columnId);
        },
        onUpdateColumn: (column) async {
          final repository = ref.read(boardRepositoryProvider);
          await repository.updateColumn(column);
        },
        onReorderColumns: (columnIds) async {
          final repository = ref.read(boardRepositoryProvider);
          await repository.reorderColumns(widget.boardId, columnIds);
        },
      ),
    );
  }

  void _showSprintManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => SprintManagementDialog(boardId: widget.boardId),
    );
  }

  void _showBoardAnalyticsDialog() {
    final boardState = ref.read(boardNotifierProvider(widget.boardId));
    if (!boardState.hasValue) return;
    final columns = boardState.value!.columns;

    showDialog(
      context: context,
      builder: (context) =>
          BoardAnalyticsDialog(boardId: widget.boardId, columns: columns),
    );
  }

  void _showExportBoardDialog() {
    final boardState = ref.read(boardNotifierProvider(widget.boardId));
    if (!boardState.hasValue) return;
    final board = boardState.value!.board;
    final columns = boardState.value!.columns;

    showDialog(
      context: context,
      builder: (context) => ExportBoardDialog(board: board, columns: columns),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Board Management',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Create and organize columns for your workflow'),
              Text('• Add cards to track tasks and projects'),
              Text('• Drag and drop cards between columns'),
              Text('• Set WIP limits to manage workload'),
              SizedBox(height: 16),
              Text(
                'Sprint Features',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Create sprints to organize work in time-boxed periods'),
              Text('• Assign cards to sprints'),
              Text('• Track sprint progress and velocity'),
              SizedBox(height: 16),
              Text(
                'Collaboration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Invite team members to your board'),
              Text('• Assign cards to specific people'),
              Text('• Comment and discuss on cards'),
            ],
          ),
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

  Widget _buildBoardView(BoardState state) {
    return MultiplayerCursors(
      boardId: widget.boardId,
      child: Column(
        children: [
          // Board header
          _buildHeader(state.board),

          // Kanban columns
          Expanded(child: _buildKanbanBoard(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(Board board) {
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: isMobile ? _buildMobileHeader(board) : _buildDesktopHeader(board),
    );
  }

  Widget _buildDesktopHeader(Board board) {
    return Row(
      children: [
        // Back button
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(8),
            minimumSize: const Size(36, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Board info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                board.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              if (board.description != null && board.description!.isNotEmpty)
                Text(
                  board.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
            ],
          ),
        ),

        // Sprint selector
        _buildSprintSelector(),
        const SizedBox(width: 12),

        // Members avatars
        _buildMembersAvatars(board.memberIds),
        const SizedBox(width: 8),

        // Board menu
        _buildMenuButton(),
      ],
    );
  }

  Widget _buildMobileHeader(Board board) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Back button, title, menu
        Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Board title
            Expanded(
              child: Text(
                board.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Board menu
            _buildMenuButton(),
          ],
        ),

        // Second row: Sprint selector and members
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSprintSelector()),
            const SizedBox(width: 8),
            _buildMembersAvatars(board.memberIds, compact: true),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton() {
    return IconButton(
      onPressed: () {
        // Get the button's position
        final RenderBox button = context.findRenderObject() as RenderBox;
        final RenderBox overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final position = button.localToGlobal(Offset.zero, ancestor: overlay);

        // Show floating menu
        final screenWidth = MediaQuery.of(context).size.width;
        final menuWidth = context.isMobile ? screenWidth - 32 : 320;
        BoardMenuOverlay.show(
          context: context,
          position: Offset(
            context.isMobile ? 16 : screenWidth - menuWidth - 16,
            position.dy + 8,
          ),
          child: _buildBoardDrawer(),
        );
      },
      icon: const Icon(Icons.more_horiz),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).drawerTheme.backgroundColor,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _buildMembersAvatars(List<String> memberIds, {bool compact = false}) {
    final displayedIds = memberIds.take(compact ? 2 : 3).toList();
    final remaining = memberIds.length - displayedIds.length;
    final avatarSize = compact ? 12.0 : 16.0;

    return Row(
      children: [
        ...displayedIds.map((memberId) {
          return Consumer(
            builder: (context, ref, child) {
              final userAsync = ref.watch(userProvider(memberId));

              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: userAsync.when(
                  data: (user) => Tooltip(
                    message: user.name,
                    child: HoverAnimatedAvatar(user: user),
                  ),
                  loading: () => CircleAvatar(
                    radius: avatarSize,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  error: (_, __) => CircleAvatar(
                    radius: avatarSize,
                    backgroundColor: Colors.red.shade100,
                    child: Icon(
                      Icons.error,
                      size: avatarSize,
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            },
          );
        }),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: avatarSize,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                '+$remaining',
                style: TextStyle(
                  fontSize: compact ? 8 : 10,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showInviteMemberDialog() async {
    await showDialog(
      context: context,
      builder: (context) => InviteMemberDialog(boardId: widget.boardId),
    );
    // Smoothly refresh board data to show new members
    await ref
        .read(boardNotifierProvider(widget.boardId).notifier)
        .refreshBoard();
  }

  Widget _buildSprintSelector() {
    final sprintsAsync = ref.watch(boardSprintsProvider(widget.boardId));
    final activeSprint = ref.watch(sprintNotifierProvider(widget.boardId));

    return sprintsAsync.when(
      data: (sprints) {
        return PopupMenuButton<String>(
          tooltip: 'Sprint Management',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: activeSprint != null
                  ? context.surfaceColor
                  : context.surfaceVariantColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: activeSprint != null
                    ? context.successColor
                    : context.borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 6),
                Text(
                  activeSprint?.name ?? 'No Active Sprint',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activeSprint != null
                        ? Theme.brightnessOf(context) == Brightness.light
                              ? Colors.black
                              : Colors.white
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            // Create new sprint
            PopupMenuItem(
              value: 'create',
              child: Row(
                children: [
                  Icon(Icons.add, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text('Create Sprint'),
                ],
              ),
            ),
            if (sprints.isNotEmpty) const PopupMenuDivider(),
            // List all sprints
            ...sprints.map((sprint) {
              final isActive = sprint.status == SprintStatus.active;
              return PopupMenuItem(
                value: sprint.id,
                child: Row(
                  children: [
                    Icon(
                      isActive ? Icons.play_circle : Icons.schedule,
                      size: 18,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sprint.name,
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            '${sprint.status.toString().split('.').last} - ${sprint.cardIds.length} cards',
                            style: TextStyle(
                              fontSize: 11,
                              color: isActive
                                  ? Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Theme.of(context).primaryColor
                                        : Colors.white
                                  : Theme.of(context).brightness ==
                                        Brightness.light
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onSelected: (value) async {
            if (value == 'create') {
              await showDialog(
                context: context,
                builder: (context) =>
                    CreateSprintDialog(boardId: widget.boardId),
              );
              // Sprint data is refreshed inside the dialog
            } else {
              // Sprint selected - could show sprint details or start it
              final sprint = sprints.firstWhere((s) => s.id == value);
              if (sprint.status == SprintStatus.planning) {
                // Ask if they want to start the sprint
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Start Sprint?'),
                    content: Text('Start "${sprint.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Start'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await ref
                      .read(sprintNotifierProvider(widget.boardId).notifier)
                      .startSprint(sprint.id);
                }
              }
            }
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => CreateSprintDialog(boardId: widget.boardId),
          );
        },
        icon: const Icon(Icons.timer),
        tooltip: 'Create Sprint',
      ),
    );
  }

  Widget _buildKanbanBoard(BoardState state) {
    final columns = state.columns;
    final isMobile = context.isMobile;

    if (isMobile) {
      // Mobile: Vertical scrolling list
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: columns.length + 1, // +1 for add button
        itemBuilder: (context, index) {
          if (index == columns.length) {
            return _buildAddColumnButton();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KanbanColumn(
              column: columns[index],
              boardId: state.board.id,
            ),
          );
        },
      );
    }

    // Desktop: Horizontal scrolling
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Render each column
            ...columns.map(
              (column) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: KanbanColumn(column: column, boardId: state.board.id),
              ),
            ),

            // Add column button
            _buildAddColumnButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddColumnButton() {
    final isMobile = context.isMobile;

    return Container(
      width: isMobile ? double.infinity : 280,
      padding: const EdgeInsets.all(16),
      child: OllieButton.outline(
        text: 'Add Column',
        onPressed: () => _showAddColumnDialog(),
        icon: Icons.add,
        width: double.infinity,
      ),
    );
  }

  void _showAddColumnDialog() {
    showDialog(
      context: context,
      builder: (context) => AddColumnDialog(
        onCreateColumn: (name, color, wipLimit) async {
          final column = await ref
              .read(boardNotifierProvider(widget.boardId).notifier)
              .createColumn(name: name, color: color, wipLimit: wipLimit);
          return column != null;
        },
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
            'Failed to load board',
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
          OllieButton.outline(
            text: 'Go Back',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
