import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/board_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/sprint_provider.dart';
import '../../models/board.dart';
import '../../models/sprint.dart';
import '../../components/kanban_column.dart';
import '../../components/ollie_ui/ollie_button.dart';
import '../../components/add_column_dialog.dart';
import '../../components/invite_member_dialog.dart';
import '../../components/create_sprint_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    final boardState = ref.watch(boardNotifierProvider(widget.boardId));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: boardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (state) => _buildBoardView(state),
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
            onPressed: () {},
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
