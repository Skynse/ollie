// Custom button that feels good to use

import 'package:flutter/material.dart';

enum OllieButtonVariant { primary, secondary, outline, danger, text }

class OllieButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final OllieButtonVariant variant;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool loading;
  final bool disabled;

  // Default constructor (primary button)
  const OllieButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.icon,
    this.loading = false,
    this.disabled = false,
  }) : variant = OllieButtonVariant.primary;

  // Named constructor for secondary variant
  const OllieButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.icon,
    this.loading = false,
    this.disabled = false,
  }) : variant = OllieButtonVariant.secondary;

  // Named constructor for outline variant
  const OllieButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.icon,
    this.loading = false,
    this.disabled = false,
  }) : variant = OllieButtonVariant.outline;

  // Named constructor for danger/destructive actions
  const OllieButton.danger({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.icon,
    this.loading = false,
    this.disabled = false,
  }) : variant = OllieButtonVariant.danger;

  // Named constructor for text-only button
  const OllieButton.text({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height,
    this.icon,
    this.loading = false,
    this.disabled = false,
  }) : variant = OllieButtonVariant.text;

  // Named constructor for icon button
  const OllieButton.icon({
    super.key,
    required this.text,
    required this.onPressed,
    required this.icon,
    this.width,
    this.height,
    this.loading = false,
    this.disabled = false,
  }) : variant = OllieButtonVariant.primary;

  @override
  _OllieButtonState createState() => _OllieButtonState();
}

class _OllieButtonState extends State<OllieButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.disabled) return Colors.grey.shade300;

    switch (widget.variant) {
      case OllieButtonVariant.primary:
        return Colors.blue;
      case OllieButtonVariant.secondary:
        return Colors.grey.shade700;
      case OllieButtonVariant.outline:
        return Colors.transparent;
      case OllieButtonVariant.danger:
        return Colors.red;
      case OllieButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (widget.disabled) return Colors.grey.shade500;

    switch (widget.variant) {
      case OllieButtonVariant.primary:
      case OllieButtonVariant.secondary:
      case OllieButtonVariant.danger:
        return Colors.white;
      case OllieButtonVariant.outline:
        return Colors.blue;
      case OllieButtonVariant.text:
        return Colors.blue;
    }
  }

  Border? _getBorder() {
    if (widget.variant == OllieButtonVariant.outline) {
      return Border.all(
        color: widget.disabled ? Colors.grey.shade300 : Colors.blue,
        width: 2,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: widget.disabled || widget.loading
            ? null
            : (_) => _controller.forward(),
        onTapUp: widget.disabled || widget.loading
            ? null
            : (_) => _controller.reverse(),
        onTapCancel: widget.disabled || widget.loading
            ? null
            : () => _controller.reverse(),
        onTap: widget.disabled || widget.loading ? null : widget.onPressed,
        child: Container(
          width: widget.width ?? 200,
          height: widget.height ?? 50,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(10),
            border: _getBorder(),
            boxShadow:
                widget.variant == OllieButtonVariant.text || widget.disabled
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getTextColor(),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: _getTextColor(), size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: _getTextColor(),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
