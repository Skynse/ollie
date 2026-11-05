import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_column.dart';
import '../providers/board_provider.dart';
import 'ollie_ui/ollie_context_menu.dart';
import 'ollie_ui/theme_extensions.dart';

/// Enhanced column header with WIP limit indicators and better styling
class EnhancedColumnHeader extends ConsumerStatefulWidget {
  final BoardColumn column;
  final String boardId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EnhancedColumnHeader({
    super.key,
    required this.column,
    required this.boardId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<EnhancedColumnHeader> createState() =>
      _EnhancedColumnHeaderState();
}

class _EnhancedColumnHeaderState extends ConsumerState<EnhancedColumnHeader> {
  @override
  Widget build(BuildContext context) {
    final cardCount = ref.watch(
      boardNotifierProvider(widget.boardId).select(
        (asyncState) =>
            asyncState.value?.columnCards[widget.column.id]?.length ?? 0,
      ),
    );

    final wipLimit = widget.column.wipLimit;
    final isNearLimit =
        wipLimit != null && cardCount >= (wipLimit * 0.8).floor();
    final isOverLimit = wipLimit != null && cardCount > wipLimit;
    final columnColor = _parseColor(widget.column.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            columnColor.withValues(alpha: 0.08),
            columnColor.withValues(alpha: 0.03),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: columnColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Column color indicator
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [columnColor, columnColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: columnColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Column name
              Expanded(
                child: Text(
                  widget.column.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: context.textColor,
                  ),
                ),
              ),

              // Card count badge
              _buildCardCountBadge(
                cardCount,
                wipLimit,
                isNearLimit,
                isOverLimit,
                columnColor,
              ),

              const SizedBox(width: 8),

              // Column menu
              InkWell(
                onTapDown: (details) {
                  showOllieMenu(
                    position: Offset(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                    ),
                    items: [
                      OllieMenuItem(
                        title: 'Edit Column',
                        icon: Icons.edit_outlined,
                        onTap: widget.onEdit,
                      ),
                      OllieMenuItem(
                        title: 'Rebalance Card Ranks',
                        icon: Icons.sync,
                        onTap: () async {
                          await ref
                              .read(
                                boardNotifierProvider(widget.boardId).notifier,
                              )
                              .rebalanceColumnRanks(widget.column.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Card ranks rebalanced successfully',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      OllieMenuItem(
                        title: 'Delete Column',
                        icon: Icons.delete_outline,
                        onTap: widget.onDelete,
                      ),
                    ],
                    context: context,
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: context.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),

          // WIP limit indicator
          if (wipLimit != null) ...[
            const SizedBox(height: 12),
            _buildWipLimitIndicator(
              cardCount,
              wipLimit,
              isNearLimit,
              isOverLimit,
              columnColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardCountBadge(
    int cardCount,
    int? wipLimit,
    bool isNearLimit,
    bool isOverLimit,
    Color columnColor,
  ) {
    Color badgeColor;
    Color textColor;

    if (isOverLimit) {
      badgeColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else if (isNearLimit) {
      badgeColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else {
      badgeColor = columnColor.withValues(alpha: 0.15);
      textColor = columnColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverLimit
              ? Colors.red.shade200
              : isNearLimit
              ? Colors.orange.shade200
              : columnColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOverLimit)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.warning_rounded, size: 14, color: textColor),
            ),
          Text(
            wipLimit != null ? '$cardCount/$wipLimit' : '$cardCount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWipLimitIndicator(
    int cardCount,
    int wipLimit,
    bool isNearLimit,
    bool isOverLimit,
    Color columnColor,
  ) {
    final percentage = (cardCount / wipLimit).clamp(0.0, 1.0);
    Color indicatorColor;

    if (isOverLimit) {
      indicatorColor = Colors.red.shade600;
    } else if (isNearLimit) {
      indicatorColor = Colors.orange.shade600;
    } else {
      indicatorColor = columnColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'WIP Limit',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.secondaryTextColor,
              ),
            ),
            Text(
              isOverLimit
                  ? 'Over limit!'
                  : isNearLimit
                  ? 'Near limit'
                  : 'On track',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: indicatorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage > 1.0 ? 1.0 : percentage,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        indicatorColor,
                        indicatorColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: indicatorColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
