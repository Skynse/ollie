import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/board_provider.dart';
import '../../models/board.dart';
import '../../components/kanban_column.dart';
import '../../components/ollie_ui/ollie_button.dart';
import '../../components/add_column_dialog.dart';

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
    return Row(
      children: [
        ...memberIds
            .take(3)
            .map(
              (memberId) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    'U',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        if (memberIds.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                '+${memberIds.length - 3}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
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
