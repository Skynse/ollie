import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/board_provider.dart';
import '../../providers/boards_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/sprint_provider.dart';
import '../../models/board.dart';
import '../../models/sprint.dart';
import '../../components/kanban_column.dart';
import '../../components/ollie_ui/ollie_button.dart';
import '../../components/add_column_dialog.dart';
import '../../components/invite_member_dialog.dart';
import '../../components/create_sprint_dialog.dart';
import '../../components/edit_board_dialog.dart';
import '../../components/manage_members_dialog.dart';
import '../../components/manage_columns_dialog.dart';
import '../../components/sprint_management_dialog.dart';
import '../../components/board_analytics_dialog.dart';
import '../../components/export_board_dialog.dart';

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

      endDrawer: Drawer(child: _buildBoardDrawer()),
      backgroundColor: Colors.grey.shade100,
      body: boardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (state) => _buildBoardView(state),
      ),
    );
  }

  Widget _buildBoardDrawer() {
    final boardState = ref.watch(boardNotifierProvider(widget.boardId));
    final board = boardState?.value?.board;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade500],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dashboard, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        board?.name ?? 'Board Settings',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Board Management',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Drawer Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),

                // Board Settings Section
                _buildDrawerSection('Board Settings'),
                _buildDrawerTile(
                  icon: Icons.edit,
                  title: 'Edit Board Details',
                  subtitle: 'Name, description, and settings',
                  onTap: () {
                    Navigator.pop(context);
                    _showEditBoardDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.color_lens,
                  title: 'Board Theme',
                  subtitle: 'Customize appearance',
                  onTap: () {
                    Navigator.pop(context);
                    _showBoardThemeDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.archive,
                  title: 'Archive Board',
                  subtitle: 'Move to archived boards',
                  onTap: () {
                    Navigator.pop(context);
                    _showArchiveBoardDialog();
                  },
                ),

                const Divider(height: 32),

                // Members Section
                _buildDrawerSection('Members'),
                _buildDrawerTile(
                  icon: Icons.people,
                  title: 'Manage Members',
                  subtitle: '${board?.memberIds.length ?? 0} members',
                  onTap: () {
                    Navigator.pop(context);
                    _showManageMembersDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.person_add,
                  title: 'Invite Members',
                  subtitle: 'Add people to this board',
                  onTap: () {
                    Navigator.pop(context);
                    _showInviteMemberDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.admin_panel_settings,
                  title: 'Roles & Permissions',
                  subtitle: 'Manage access levels',
                  onTap: () {
                    Navigator.pop(context);
                    _showRolesPermissionsDialog();
                  },
                ),

                const Divider(height: 32),

                // Columns Section
                _buildDrawerSection('Columns'),
                _buildDrawerTile(
                  icon: Icons.view_column,
                  title: 'Manage Columns',
                  subtitle: '${board?.columnIds.length ?? 0} columns',
                  onTap: () {
                    Navigator.pop(context);
                    _showManageColumnsDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.add_box,
                  title: 'Add Column',
                  subtitle: 'Create a new column',
                  onTap: () {
                    Navigator.pop(context);
                    _showAddColumnDialog();
                  },
                ),

                const Divider(height: 32),

                // Sprints Section
                _buildDrawerSection('Sprints'),
                _buildDrawerTile(
                  icon: Icons.timer,
                  title: 'Sprint Management',
                  subtitle: 'View and manage sprints',
                  onTap: () {
                    Navigator.pop(context);
                    _showSprintManagementDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.add_circle,
                  title: 'Create Sprint',
                  subtitle: 'Start a new sprint',
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) =>
                          CreateSprintDialog(boardId: widget.boardId),
                    );
                  },
                ),

                const Divider(height: 32),

                // Export & Reports Section
                _buildDrawerSection('Export & Reports'),
                _buildDrawerTile(
                  icon: Icons.analytics,
                  title: 'Board Analytics',
                  subtitle: 'View performance metrics',
                  onTap: () {
                    Navigator.pop(context);
                    _showBoardAnalyticsDialog();
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.file_download,
                  title: 'Export Board',
                  subtitle: 'Download as CSV or JSON',
                  onTap: () {
                    Navigator.pop(context);
                    _showExportBoardDialog();
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom Actions
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                _buildDrawerTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    _showHelpDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
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
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.blue.shade700, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
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
      builder: (context) => AlertDialog(
        title: const Text('Archive Board'),
        content: Text(
          'Are you sure you want to archive "${board.name}"?\n\n'
          'The board will be hidden from your active boards list. '
          'You can restore it later from archived boards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              // Archive functionality would be implemented in repository
              // For now, show a message that this is coming soon
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Archive functionality coming soon. '
                    'Board archiving will be implemented in the next update.',
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _showManageMembersDialog() {
    final boardState = ref.read(boardNotifierProvider(widget.boardId));
    if (!boardState.hasValue) return;
    final board = boardState.value!.board;

    showDialog(
      context: context,
      builder: (context) => ManageMembersDialog(
        boardId: widget.boardId,
        memberIds: board.memberIds,
        createdBy: board.createdBy,
        onRemoveMember: (userId) async {
          final repository = ref.read(boardRepositoryProvider);
          await repository.removeMember(widget.boardId, userId);
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
    final sprintsAsync = ref.read(boardSprintsProvider(widget.boardId));
    final activeSprint = ref.read(sprintNotifierProvider(widget.boardId));

    sprintsAsync.when(
      data: (sprints) {
        showDialog(
          context: context,
          builder: (context) => SprintManagementDialog(
            sprints: sprints,
            activeSprint: activeSprint,
            onStartSprint: (sprintId) async {
              await ref
                  .read(sprintNotifierProvider(widget.boardId).notifier)
                  .startSprint(sprintId);
            },
            onCompleteSprint: (sprintId) async {
              await ref
                  .read(sprintNotifierProvider(widget.boardId).notifier)
                  .completeSprint(sprintId);
            },
            onDeleteSprint: (sprintId) async {
              final repository = ref.read(sprintRepositoryProvider);
              await repository.deleteSprint(sprintId);
              ref.refresh(boardSprintsProvider(widget.boardId));
              ref.refresh(sprintNotifierProvider(widget.boardId));
              setState(() {});
            },
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Loading sprints...')));
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sprints: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      },
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
    return Column(
      children: [
        // Board header
        _buildHeader(state.board),

        // Kanban columns
        Expanded(child: _buildKanbanBoard(state)),
      ],
    );
  }

  Widget _buildHeader(Board board) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Board info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  board.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (board.description != null && board.description!.isNotEmpty)
                  Text(
                    board.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),

          // Sprint selector
          _buildSprintSelector(),
          const SizedBox(width: 16),

          // Members avatars
          _buildMembersAvatars(board.memberIds),
          const SizedBox(width: 16),

          // Board menu
          IconButton(
            onPressed: () {
              // will have options for editing board details, adding/removing members,
              // sprint settings mostly

              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: const Icon(Icons.more_horiz),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersAvatars(List<String> memberIds) {
    final displayedIds = memberIds.take(3).toList();
    final remaining = memberIds.length - displayedIds.length;

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
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  loading: () => CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  error: (_, __) => CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.red.shade100,
                    child: Icon(Icons.error, size: 16, color: Colors.red),
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
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                '+$remaining',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        // Invite button
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => _showInviteMemberDialog(),
            icon: const Icon(Icons.person_add, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            tooltip: 'Invite member',
          ),
        ),
      ],
    );
  }

  void _showInviteMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => InviteMemberDialog(boardId: widget.boardId),
    );
  }

  Widget _buildSprintSelector() {
    final sprintsAsync = ref.watch(boardSprintsProvider(widget.boardId));
    final activeSprint = ref.watch(sprintNotifierProvider(widget.boardId));

    return sprintsAsync.when(
      data: (sprints) {
        return PopupMenuButton<String>(
          tooltip: 'Sprint Management',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeSprint != null
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeSprint != null
                    ? Colors.green.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 18,
                  color: activeSprint != null
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  activeSprint?.name ?? 'No Active Sprint',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: activeSprint != null
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: activeSprint != null
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
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
                      color: isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
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
                              color: Colors.grey.shade600,
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
              showDialog(
                context: context,
                builder: (context) =>
                    CreateSprintDialog(boardId: widget.boardId),
              );
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

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Render each column
            ...columns.map(
              (column) => Padding(
                padding: const EdgeInsets.only(right: 16),
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
    return Container(
      width: 300,
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
