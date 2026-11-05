import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/edit_column_dialog.dart';
import '../models/board_column.dart';
import '../models/card.dart' as model;
import '../providers/board_provider.dart';
import '../utils/responsive.dart';
import 'kanban_card.dart';
import 'add_card_dialog.dart';
import 'enhanced_column_header.dart';
import 'ollie_ui/ollie_toast.dart';
import 'ollie_ui/theme_extensions.dart';

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
  String? _hoveredCardId;

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
        final isMobile = context.isMobile;

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: isMobile ? double.infinity : 280,
            decoration: BoxDecoration(
              color: context.surfaceVariantColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor),
              boxShadow:
                  _animationController.isAnimating ||
                      _animationController.value > 0
                  ? context.shadowMedium
                  : [],
            ),
            child: child,
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = context.isMobile;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Column header
              EnhancedColumnHeader(
                column: widget.column,
                boardId: widget.boardId,
                onEdit: () => _editColumn(widget.column),
                onDelete: () => _deleteColumn(),
              ),

              // Cards list - conditionally use Flexible based on layout
              if (isMobile)
                // Mobile: No Flexible (inside ListView with unbounded height)
                boardStateAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, st) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Error'),
                    ),
                  ),
                  data: (boardState) {
                    final columnCards =
                        boardState.columnCards[widget.column.id] ?? [];
                    return _buildCardList(columnCards);
                  },
                )
              else
                // Desktop: With Flexible (inside horizontal scroll with bounded height)
                Flexible(
                  child: boardStateAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (err, st) => const Center(child: Text('Error')),
                    data: (boardState) {
                      final columnCards =
                          boardState.columnCards[widget.column.id] ?? [];
                      return _buildCardList(columnCards);
                    },
                  ),
                ),

              // Add card button
              _buildAddCardButton(context, ref),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardList(List<model.Card> cards) {
    if (cards.isEmpty) {
      return DragTarget<model.Card>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) async {
          await ref
              .read(boardNotifierProvider(widget.boardId).notifier)
              .moveCard(
                card: details.data,
                targetColumnId: widget.column.id,
                targetPosition: 0,
              );
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isHovering ? 100 : 50,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: isHovering
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.primaryColor.withValues(alpha: 0.1),
                        context.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.primaryColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.borderColor.withValues(alpha: 0.3),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
            child: Center(
              child: Text(
                isHovering ? 'Drop here' : 'No cards',
                style: TextStyle(
                  color: isHovering
                      ? context.primaryColor
                      : context.secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      children: [
        ...cards.asMap().entries.map((entry) {
          final cardIndex = entry.key;
          final card = entry.value;

          // Check if we should show space above this card
          final hoveredIndex = _hoveredCardId != null
              ? cards.indexWhere((c) => c.id == _hoveredCardId)
              : -1;
          final showSpaceAbove = hoveredIndex >= 0 && cardIndex == hoveredIndex;

          return DragTarget<model.Card>(
            key: ValueKey(card.id),
            onWillAcceptWithDetails: (details) {
              // Accept all cards except itself
              if (details.data.id != card.id) {
                // Set hovered state immediately when accepting
                if (_hoveredCardId != card.id) {
                  setState(() {
                    _hoveredCardId = card.id;
                  });
                }
                return true;
              }
              return false;
            },
            onLeave: (data) {
              // Clear hovered state when card leaves
              if (_hoveredCardId == card.id) {
                setState(() {
                  _hoveredCardId = null;
                });
              }
            },
            onAcceptWithDetails: (details) async {
              // Clear hover state
              setState(() {
                _hoveredCardId = null;
              });

              // Drop before this card
              await ref
                  .read(boardNotifierProvider(widget.boardId).notifier)
                  .moveCard(
                    card: details.data,
                    targetColumnId: widget.column.id,
                    targetPosition: cardIndex,
                  );
            },
            builder: (context, candidateData, rejectedData) {
              return Padding(
                padding: EdgeInsets.only(
                  top: showSpaceAbove ? 100.0 : 0.0,
                  left: 4,
                  right: 4,
                  bottom: 4,
                ),
                child: KanbanCard(card: card, boardId: widget.boardId),
              );
            },
          );
        }),
        // Drop zone at bottom for all drops (including same column reordering)
        DragTarget<model.Card>(
          onWillAcceptWithDetails: (details) {
            // Accept all cards
            return true;
          },
          onAcceptWithDetails: (details) async {
            // Drop at the end
            await ref
                .read(boardNotifierProvider(widget.boardId).notifier)
                .moveCard(
                  card: details.data,
                  targetColumnId: widget.column.id,
                  targetPosition: cards.length,
                );
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isHovering ? 80 : 40,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: isHovering
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.primaryColor.withValues(alpha: 0.1),
                          context.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    )
                  : null,
              child: isHovering
                  ? Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: context.primaryColor,
                        size: 20,
                      ),
                    )
                  : null,
            );
          },
        ),
      ],
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
            Icon(Icons.add, size: 18, color: context.secondaryTextColor),
            const SizedBox(width: 8),
            Text(
              'Add card',
              style: TextStyle(
                fontSize: 14,
                color: context.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
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
              );
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
