// Custom button that feels good to use

import 'package:flutter/material.dart';
import 'theme_constants.dart';

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

  Color _getBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (widget.disabled) {
      return brightness == Brightness.light
          ? OllieThemeConstants.lightDisabled
          : OllieThemeConstants.darkDisabled;
    }

    switch (widget.variant) {
      case OllieButtonVariant.primary:
        return OllieThemeConstants.getPrimaryColor(brightness);
      case OllieButtonVariant.secondary:
        return brightness == Brightness.light
            ? OllieThemeConstants.lightSecondary
            : OllieThemeConstants.darkSecondary;
      case OllieButtonVariant.outline:
        return Colors.transparent;
      case OllieButtonVariant.danger:
        return brightness == Brightness.light
            ? OllieThemeConstants.lightDanger
            : OllieThemeConstants.darkDanger;
      case OllieButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color _getTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (widget.disabled) {
      return brightness == Brightness.light
          ? OllieThemeConstants.lightTextDisabled
          : OllieThemeConstants.darkTextDisabled;
    }

    switch (widget.variant) {
      case OllieButtonVariant.primary:
      case OllieButtonVariant.danger:
        return Colors.white;
      case OllieButtonVariant.secondary:
        return brightness == Brightness.light ? Colors.white : Colors.black;
      case OllieButtonVariant.outline:
      case OllieButtonVariant.text:
        return OllieThemeConstants.getPrimaryColor(brightness);
    }
  }

  Border? _getBorder(BuildContext context) {
    if (widget.variant == OllieButtonVariant.outline) {
      final brightness = Theme.of(context).brightness;
      return Border.all(
        color: widget.disabled
            ? OllieThemeConstants.getBorderColor(brightness)
            : OllieThemeConstants.getPrimaryColor(brightness),
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
        child: Builder(
          builder: (context) {
            final brightness = Theme.of(context).brightness;
            return Container(
              width: widget.width ?? 200,
              height: widget.height ?? 50,
              decoration: BoxDecoration(
                color: _getBackgroundColor(context),
                borderRadius: BorderRadius.circular(
                  OllieThemeConstants.borderRadiusMedium,
                ),
                border: _getBorder(context),
                boxShadow:
                    widget.variant == OllieButtonVariant.text || widget.disabled
                    ? null
                    : OllieThemeConstants.getShadow(brightness),
              ),
              child: Center(
                child: widget.loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getTextColor(context),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: _getTextColor(context),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: _getTextColor(context),
                              fontSize: OllieThemeConstants.fontSizeBody,
                              fontWeight:
                                  OllieThemeConstants.fontWeightSemiBold,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
