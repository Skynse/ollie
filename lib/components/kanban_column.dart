import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_column.dart';
import '../models/card.dart' as model;
import '../providers/board_provider.dart';
import '../providers/auth_provider.dart';
import 'kanban_card.dart';
import 'add_card_dialog.dart';

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
          _buildHeader(context, ref),

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
    return DragTarget<model.Card>(
      onWillAcceptWithDetails: (details) {
        final draggedCard = details.data;
        // Don't allow dropping in the same position in the same column
        if (draggedCard.columnId == widget.column.id) {
          final originalIndex = cards.indexWhere((c) => c.id == draggedCard.id);
          if (originalIndex == position || originalIndex + 1 == position) {
            return false;
          }
        }
        _onDragEnter(); // Trigger column animation
        return true;
      },
      onLeave: (_) => _onDragLeave(), // Stop column animation
      onAcceptWithDetails: (details) async {
        _onDragLeave();
        final draggedCard = details.data;

        await ref
            .read(boardNotifierProvider(widget.boardId).notifier)
            .moveCard(
              card: draggedCard,

              targetColumnId: widget.column.id,
              targetPosition: position,
            );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        if (isHovering) {
          // Show a placeholder when a card is being dragged over
          return Container(
            height: 80, // Height of the placeholder
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: Center(child: Icon(Icons.add, color: Colors.blue.shade400)),
          );
        } else {
          // Empty space when not hovering
          return SizedBox(
            height: isTop || isBottom ? 4 : 8,
          ); // Smaller gap between cards
        }
      },
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final cardCount = ref.watch(
      boardNotifierProvider(widget.boardId).select(
        (asyncState) =>
            asyncState.value?.columnCards[widget.column.id]?.length ?? 0,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Column color indicator
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: _parseColor(widget.column.color),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Column name
          Expanded(
            child: Text(
              widget.column.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),

          // Card count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$cardCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),

          // Column menu
          IconButton(
            onPressed: () {
              // TODO: Show column menu
            },
            icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey.shade600),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
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

  Color _parseColor(int argbColorValue) {
    try {
      return Color(argbColorValue);
    } catch (e) {
      return Colors.grey;
    }
  }
}
