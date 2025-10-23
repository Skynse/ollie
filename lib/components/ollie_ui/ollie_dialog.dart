import 'package:flutter/material.dart';

/// Modern, clean dialog component for Ollie
/// Follows the design system with rounded corners, shadows, and sections
class OllieDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final double? width;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const OllieDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.width = 480,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with optional close button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (showCloseButton) ...[
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: content,
              ),
            ),

            // Actions footer (if any)
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActionsWithSpacing(actions),
                ),
              ),
            ] else
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionsWithSpacing(List<Widget> actions) {
    final widgets = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      widgets.add(actions[i]);
      if (i < actions.length - 1) {
        widgets.add(const SizedBox(width: 12));
      }
    }
    return widgets;
  }
}
