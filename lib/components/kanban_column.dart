import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/edit_column_dialog.dart';
import 'package:ollie/components/ollie_ui/ollie_context_menu.dart';
import '../models/board_column.dart';
import '../models/card.dart' as model;
import '../providers/board_provider.dart';
import '../providers/auth_provider.dart';
import 'kanban_card.dart';
import 'add_card_dialog.dart';
import 'enhanced_column_header.dart';
import 'enhanced_drop_zone.dart';
import 'ollie_ui/ollie_toast.dart';

/// A kanban column component displaying a list of cards
class KanbanColumn extends ConsumerStatefulWidget {
  final BoardColumn column;
  final String boardId;

  const KanbanColumn({super.key, required this.column, required this.boardId});

  @override
  ConsumerState<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends ConsumerState<KanbanColumn>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardStateAsync = ref.watch(boardNotifierProvider(widget.boardId));

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow:
                  _animationController.isAnimating ||
                      _animationController.value > 0
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          EnhancedColumnHeader(
            column: widget.column,
            boardId: widget.boardId,
            onEdit: () => _editColumn(widget.column),
            onDelete: () => _deleteColumn(),
          ),

          // Cards list
          Flexible(
            // Use the new boardStateAsync value
            child: boardStateAsync.when(
              // The main loading/error state is now handled at the screen level,
              // but we can still show a small indicator here.
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, st) => Center(child: Text('Error')),
              data: (boardState) {
                // Get the cards for THIS specific column from the map
                final columnCards =
                    boardState.columnCards[widget.column.id] ?? [];
                return _buildCardList(columnCards);
              },
            ),
          ),

          // Add card button
          _buildAddCardButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildCardList(List<model.Card> cards) {
    // We build a list of widgets that includes cards and drop zones between them
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // We have N cards and N+1 drop zones
      itemCount: cards.length * 2 + 1,
      itemBuilder: (context, index) {
        // Even indices are drop zones
        if (index.isEven) {
          final dropPosition = index ~/ 2;
          return _buildDropZone(
            cards: cards,
            position: dropPosition,
            isTop: index == 0,
            isBottom: index == cards.length * 2,
          );
        }
        // Odd indices are the cards themselves
        else {
          final cardIndex = (index - 1) ~/ 2;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: KanbanCard(card: cards[cardIndex], boardId: widget.boardId),
          );
        }
      },
    );
  }

  void _onDragEnter() {
    _animationController.forward();
  }

  void _onDragLeave() {
    _animationController.reverse();
  }

  Widget _buildDropZone({
    required List<model.Card> cards,
    required int position,
    bool isTop = false,
    bool isBottom = false,
  }) {
    return EnhancedDropZone(
      cards: cards,
      position: position,
      isTop: isTop,
      isBottom: isBottom,
      columnId: widget.column.id,
      onAccept: (card, targetColumnId, targetPosition) async {
        await ref
            .read(boardNotifierProvider(widget.boardId).notifier)
            .moveCard(
              card: card,
              targetColumnId: targetColumnId,
              targetPosition: targetPosition,
            );
      },
      onDragEnter: _onDragEnter,
      onDragLeave: _onDragLeave,
    );
  }

  Future<void> _editColumn(BoardColumn column) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditColumnDialog(column: column),
    );

    if (result != null && mounted) {
      try {
        final updatedColumn = column.copyWith(
          name: result['name'] as String,
          color: result['color'] as int,
          wipLimit: result['wipLimit'] as int?,
        );
        await ref
            .read(boardNotifierProvider(widget.boardId).notifier)
            .updateColumn(updatedColumn);
      } catch (e) {
        if (mounted) {
          OllieToast.error(context, 'Failed to update column: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _deleteColumn() async {
    final confirmed = await showConfirmationDialog(
      context,
      'Delete Column',
      'Are you sure you want to delete this column? All cards will be removed.',
    );

    if (confirmed == true) {
      await ref
          .read(boardNotifierProvider(widget.boardId).notifier)
          .deleteColumn(widget.column.id);
    }
  }

  Widget _buildAddCardButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _showAddCardDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.add, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Add card',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    final userId = authState.user?.$id;

    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => AddCardDialog(
        onCreateCard: ({required title, description, required priority}) async {
          final card = await ref
              .read(boardNotifierProvider(widget.boardId).notifier)
              .createCard(
                columnId: widget.column.id,
                title: title,
                description: description,
                priority: priority,
                createdBy: userId,
              );
          // Real-time updates will handle refreshing the cards automatically
          return card != null;
        },
      ),
    );
  }
}

Future<bool?> showConfirmationDialog(
  BuildContext context,
  String title,
  String content,
) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false); // Returns false when cancelled
            },
          ),
          TextButton(
            child: const Text('Confirm'),
            onPressed: () {
              Navigator.of(context).pop(true); // Returns true when confirmed
            },
          ),
        ],
      );
    },
  );
}
