import 'package:flutter/material.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';
import '../utils/responsive.dart';

/// Custom floating menu overlay for board settings
class BoardMenuOverlay extends StatelessWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const BoardMenuOverlay({
    super.key,
    required this.child,
    required this.onDismiss,
  });

  static OverlayEntry? _currentOverlay;

  /// Show the board menu at a specific position
  static void show({
    required BuildContext context,
    required Offset position,
    required Widget child,
  }) {
    // Remove any existing overlay
    hide();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => BoardMenuOverlay(
        onDismiss: () => hide(),
        child: _PositionedMenu(position: position, child: child),
      ),
    );

    overlay.insert(entry);
    _currentOverlay = entry;
  }

  /// Hide the current overlay
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss overlay when tapping outside
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
        ),
        // The actual menu
        child,
      ],
    );
  }
}

class _PositionedMenu extends StatelessWidget {
  final Offset position;
  final Widget child;

  const _PositionedMenu({required this.position, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = context.isMobile;

    // Calculate position ensuring menu stays on screen
    double left = position.dx;
    double top = position.dy;

    // Menu width (responsive)
    final menuWidth = isMobile ? screenSize.width - 32.0 : 320.0;
    const menuMaxHeight = 600.0;

    if (isMobile) {
      // Mobile: Full width, positioned from top
      left = 16.0;
      top = 60.0; // Below header
    } else {
      // Desktop: Calculate optimal position
      // Adjust if too far right
      if (left + menuWidth > screenSize.width) {
        left = screenSize.width - menuWidth - 16;
      }

      // Adjust if too far down
      if (top + menuMaxHeight > screenSize.height) {
        top = screenSize.height - menuMaxHeight - 16;
      }

      // Keep some padding from edges
      left = left.clamp(16.0, screenSize.width - menuWidth - 16);
      top = top.clamp(16.0, screenSize.height - 100);
    }

    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * value),
            alignment: Alignment.topRight,
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: context.surfaceColor,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          child: Container(
            width: menuWidth,
            constraints: BoxConstraints(
              maxHeight: isMobile ? screenSize.height * 0.8 : menuMaxHeight,
            ),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
