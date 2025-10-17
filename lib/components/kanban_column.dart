import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_column.dart';
import '../models/card.dart' as model;
import '../providers/board_provider.dart';
import '../providers/auth_provider.dart';
import 'kanban_card.dart';
import 'add_card_dialog.dart';

/// A kanban column component displaying a list of cards
class KanbanColumn extends ConsumerWidget {
  final BoardColumn column;
  final String boardId;

  const KanbanColumn({super.key, required this.column, required this.boardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(columnCardsProvider(column.id));

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column header
          _buildHeader(context, ref),

          // Cards list with drag target
          Flexible(
            child: DragTarget<model.Card>(
              onWillAcceptWithDetails: (details) =>
                  details.data.columnId != column.id,
              onAcceptWithDetails: (details) async {
                final draggedCard = details.data;
                // Don't move if already in this column
                if (draggedCard.columnId == column.id) return;

                // Move card to this column
                await ref
                    .read(boardNotifierProvider(boardId).notifier)
                    .moveCard(
                      cardId: draggedCard.id,
                      targetColumnId: column.id,
                      targetPosition: 0, // Add to top of column
                    );
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;

                return Container(
                  decoration: BoxDecoration(
                    color: isHovering
                        ? Colors.blue.shade50
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: cardsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Error loading cards',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                    data: (columnCards) => ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: columnCards.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: KanbanCard(
                            card: columnCards[index],
                            boardId: boardId,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Add card button
          _buildAddCardButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(columnCardsProvider(column.id));
    final cardCount = cardsAsync.maybeWhen(
      data: (cards) => cards.length,
      orElse: () => 0,
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
              color: _parseColor(column.color),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Column name
          Expanded(
            child: Text(
              column.name,
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
              .read(boardNotifierProvider(boardId).notifier)
              .createCard(
                columnId: column.id,
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
