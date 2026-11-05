import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';
import 'package:ollie/models/board.dart';
import 'package:ollie/screens/home/utils/time_formatter.dart';

/// Board card widget - enhanced with hover effects and colored headers
class BoardCard extends StatefulWidget {
  final Board board;
  final int index;

  const BoardCard({super.key, required this.board, required this.index});

  @override
  State<BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Color palette for board headers
  static const List<Color> boardColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFF6366F1), // Indigo
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _boardColor => boardColors[widget.index % boardColors.length];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? _boardColor.withValues(alpha: 0.3)
                  : context.borderColor,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? _boardColor.withValues(alpha: 0.15)
                    : context.shadowSmall.first.color,
                blurRadius: _isHovered ? 20 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/boards/${widget.board.id}'),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colored header bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _boardColor,
                          _boardColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                  ),

                  // Card content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Board name
                              Text(
                                widget.board.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: context.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Board description (if exists)
                              if (widget.board.description != null &&
                                  widget.board.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  widget.board.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.secondaryTextColor,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),

                          // Bottom section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Last updated timestamp
                              Row(
                                children: [
                                  Icon(
                                    Icons.update,
                                    size: 12,
                                    color: context.secondaryTextColor
                                        .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatTimeAgo(widget.board.updatedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Open board
                              Row(
                                children: [
                                  const Spacer(),
                                  if (_isHovered)
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                      color: _boardColor,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Board list item widget - for list view
class BoardListItem extends StatefulWidget {
  final Board board;
  final int index;

  const BoardListItem({super.key, required this.board, required this.index});

  @override
  State<BoardListItem> createState() => _BoardListItemState();
}

class _BoardListItemState extends State<BoardListItem> {
  bool _isHovered = false;

  // Color palette for board headers
  static const List<Color> boardColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEF4444), // Red
    Color(0xFF6366F1), // Indigo
  ];

  Color get _boardColor => boardColors[widget.index % boardColors.length];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? _boardColor.withValues(alpha: 0.3)
                  : context.borderColor,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? _boardColor.withValues(alpha: 0.1)
                    : context.shadowSmall.first.color,
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/boards/${widget.board.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Color indicator
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _boardColor,
                            _boardColor.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Board info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.board.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: context.textColor,
                            ),
                          ),
                          if (widget.board.description != null &&
                              widget.board.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.board.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.secondaryTextColor,
                                height: 1.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.update,
                                size: 14,
                                color: context.secondaryTextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Updated ${formatTimeAgo(widget.board.updatedAt)}',
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

                    // Arrow icon
                    if (_isHovered)
                      Icon(Icons.arrow_forward, size: 20, color: _boardColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
