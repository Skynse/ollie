import 'dart:async';
import 'package:flutter/material.dart';

// --- Data Model for Menu Items ---
void showOllieMenu({
  required BuildContext context,
  required List<OllieMenuItem> items,
  required Offset position,
  double menuWidth = 220.0,
}) {
  final overlay = Overlay.of(context);
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return _ContextMenuOverlay(
        items: items,
        position: position,
        menuWidth: menuWidth,
        onClose: () {
          overlayEntry?.remove();
        },
      );
    },
  );

  overlay.insert(overlayEntry);
}

/// Represents a single item in the custom context menu.
class OllieMenuItem {
  /// The text displayed for the menu item.
  final String title;

  /// An optional icon to display to the left of the title.
  final IconData? icon;

  /// The callback to execute when the item is tapped.
  /// If the item has sub-items, this is ignored.
  final VoidCallback? onTap;

  /// A list of sub-items to be displayed in a nested menu.
  final List<OllieMenuItem>? subItems;

  OllieMenuItem({required this.title, this.icon, this.onTap, this.subItems})
    : assert(
        subItems == null || onTap == null,
        'An item cannot have both subItems and an onTap action.',
      );
}

// --- Main Context Menu Widget ---

/// A widget that attaches a custom context menu to its child.
/// The menu is triggered by a secondary tap (right-click on desktop).
class OllieContextMenu extends StatelessWidget {
  final Widget child;
  final List<OllieMenuItem> items;
  final double menuWidth;

  const OllieContextMenu({
    super.key,
    required this.child,
    required this.items,
    this.menuWidth = 220.0,
  });

  void _showMenu(BuildContext context, TapUpDetails details) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _ContextMenuOverlay(
          items: items,
          position: details.globalPosition,
          menuWidth: menuWidth,
          onClose: () {
            overlayEntry?.remove();
          },
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) => _showMenu(context, details),
      child: child,
    );
  }
}

// --- Internal Overlay and Menu Widgets ---

/// The overlay that handles the position and dismissal of the context menu.
class _ContextMenuOverlay extends StatelessWidget {
  final List<OllieMenuItem> items;
  final Offset position;
  final double menuWidth;
  final VoidCallback onClose;

  const _ContextMenuOverlay({
    required this.items,
    required this.position,
    required this.menuWidth,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Adjust position to ensure the menu doesn't go off-screen
    final left = position.dx + menuWidth > screenSize.width
        ? position.dx - menuWidth
        : position.dx;
    final top = position.dy + (items.length * 48.0) > screenSize.height
        ? position.dy - (items.length * 48.0)
        : position.dy;

    return Stack(
      children: [
        // Full-screen GestureDetector to detect taps outside the menu to close it.
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            onSecondaryTapUp: (_) => onClose(),
            child: Container(color: Colors.transparent),
          ),
        ),
        // The menu itself
        Positioned(
          top: top,
          left: left,
          child: _MenuPanel(
            items: items,
            menuWidth: menuWidth,
            onClose: onClose,
          ),
        ),
      ],
    );
  }
}

/// Renders the main panel/card containing a list of menu items.
class _MenuPanel extends StatelessWidget {
  final List<OllieMenuItem> items;
  final double menuWidth;
  final VoidCallback onClose;

  const _MenuPanel({
    required this.items,
    required this.menuWidth,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: menuWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items
              .map(
                (item) => _MenuItemWidget(
                  item: item,
                  menuWidth: menuWidth,
                  onClose: onClose,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// Renders a single menu item and handles its hover/tap events.
class _MenuItemWidget extends StatefulWidget {
  final OllieMenuItem item;
  final double menuWidth;
  final VoidCallback onClose;

  const _MenuItemWidget({
    required this.item,
    required this.menuWidth,
    required this.onClose,
  });

  @override
  State<_MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  bool _isHovered = false;
  OverlayEntry? _subMenuOverlay;
  Timer? _hideTimer;

  void _showSubMenu() {
    _hideTimer?.cancel();
    if (_subMenuOverlay != null) return; // Already showing

    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _subMenuOverlay = OverlayEntry(
      builder: (context) {
        return _ContextMenuOverlay(
          items: widget.item.subItems!,
          position: position + Offset(widget.menuWidth - 10, 0),
          menuWidth: widget.menuWidth,
          onClose: () {
            _hideSubMenu(immediately: true);
            widget.onClose();
          },
        );
      },
    );
    Overlay.of(context).insert(_subMenuOverlay!);
  }

  void _hideSubMenu({bool immediately = false}) {
    _hideTimer?.cancel();
    if (immediately) {
      _subMenuOverlay?.remove();
      _subMenuOverlay = null;
    } else {
      // A short delay allows the user to move the mouse into the sub-menu
      _hideTimer = Timer(const Duration(milliseconds: 200), () {
        _subMenuOverlay?.remove();
        _subMenuOverlay = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSubMenu = widget.item.subItems?.isNotEmpty ?? false;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        if (hasSubMenu) {
          _showSubMenu();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        if (hasSubMenu) {
          _hideSubMenu();
        }
      },
      child: GestureDetector(
        onTap: () {
          if (!hasSubMenu) {
            widget.item.onTap?.call();
            widget.onClose();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).hoverColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.item.title,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (hasSubMenu) ...[
                const SizedBox(width: 16),
                Icon(Icons.arrow_right, size: 18, color: Colors.grey.shade600),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
