import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_constants.dart';

class OllieTextfield extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? helperText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final String? initialValue;
  final FormFieldValidator? validator;

  const OllieTextfield({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.initialValue,
    this.validator,
  });

  // Named constructor for email
  const OllieTextfield.email({
    super.key,
    this.label = 'Email',
    this.hint = 'Enter your email',
    this.errorText,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
    this.validator,
  }) : keyboardType = TextInputType.emailAddress,
       obscureText = false,
       maxLines = 1,
       maxLength = null,
       prefixIcon = Icons.email_outlined,
       suffixIcon = null,
       inputFormatters = null,
       textCapitalization = TextCapitalization.none;

  // Named constructor for password
  const OllieTextfield.password({
    super.key,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.errorText,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
    this.validator,
  }) : keyboardType = TextInputType.visiblePassword,
       obscureText = true,
       maxLines = 1,
       maxLength = null,
       prefixIcon = Icons.lock_outline,
       suffixIcon = null,
       inputFormatters = null,
       textCapitalization = TextCapitalization.none;

  // Named constructor for search
  const OllieTextfield.search({
    super.key,
    this.label,
    this.hint = 'Search...',
    this.errorText,
    this.controller,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
    this.validator,
  }) : keyboardType = TextInputType.text,
       obscureText = false,
       readOnly = false,
       maxLines = 1,
       maxLength = null,
       prefixIcon = Icons.search,
       suffixIcon = null,
       helperText = null,
       inputFormatters = null,
       textCapitalization = TextCapitalization.none;

  // Named constructor for multiline
  const OllieTextfield.multiline({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 5,
    this.maxLength,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
    this.validator,
  }) : keyboardType = TextInputType.multiline,
       obscureText = false,
       prefixIcon = null,
       suffixIcon = null,
       inputFormatters = null,
       textCapitalization = TextCapitalization.sentences;

  // Named constructor for simple text input (no icons, cleaner for dialogs)
  const OllieTextfield.simple({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  }) : obscureText = false,
       prefixIcon = null,
       suffixIcon = null,

       textCapitalization = TextCapitalization.none;

  @override
  State<OllieTextfield> createState() => _OllieTextfieldState();
}

class _OllieTextfieldState extends State<OllieTextfield> {
  late bool _obscureText;
  final FocusNode _internalFocusNode = FocusNode();

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {}); // Rebuild to show focus state
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      // Password toggle icon
      return Builder(
        builder: (context) {
          final brightness = Theme.of(context).brightness;
          return IconButton(
            icon: Icon(
              _obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: OllieThemeConstants.getSecondaryTextColor(brightness),
            ),
            onPressed: _togglePasswordVisibility,
          );
        },
      );
    }
    return widget.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Theme-aware colors
    final labelColor = hasError
        ? (isDark
              ? OllieThemeConstants.darkDanger
              : OllieThemeConstants.lightDanger)
        : OllieThemeConstants.getSecondaryTextColor(brightness);

    final textColor = widget.enabled
        ? OllieThemeConstants.getTextColor(brightness)
        : OllieThemeConstants.getSecondaryTextColor(brightness);

    final hintColor = isDark
        ? OllieThemeConstants.darkTextSecondary
        : OllieThemeConstants.lightTextSecondary;

    final borderColor = OllieThemeConstants.getBorderColor(brightness);
    final focusColor = OllieThemeConstants.getPrimaryColor(brightness);
    final errorColor = isDark
        ? OllieThemeConstants.darkDanger
        : OllieThemeConstants.lightDanger;

    final fillColor = widget.enabled
        ? (hasError
              ? (isDark ? Color(0xFF3D1F1F) : Color(0xFFFFEBEE))
              : _focusNode.hasFocus
              ? (isDark ? Color(0xFF1A2A3D) : Color(0xFFE3F2FD))
              : (isDark
                    ? OllieThemeConstants
                          .darkSurfaceContainerLowest // fill color of text field
                    : OllieThemeConstants.lightSurfaceVariant))
        : (isDark
              ? OllieThemeConstants.darkDisabled
              : OllieThemeConstants.lightDisabled);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: OllieThemeConstants.fontSizeSmall,
              fontWeight: OllieThemeConstants.fontWeightSemiBold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: OllieThemeConstants.spacingSmall),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          style: TextStyle(
            fontSize: OllieThemeConstants.fontSizeBody,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: OllieThemeConstants.fontSizeBody,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: hasError
                        ? errorColor
                        : _focusNode.hasFocus
                        ? focusColor
                        : hintColor,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: OllieThemeConstants.spacingMedium,
              vertical: OllieThemeConstants.spacingMedium,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                OllieThemeConstants.borderRadiusMedium,
              ),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                OllieThemeConstants.borderRadiusMedium,
              ),
              borderSide: BorderSide(
                color: hasError ? errorColor : borderColor,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                OllieThemeConstants.borderRadiusMedium,
              ),
              borderSide: BorderSide(
                color: hasError ? errorColor : focusColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                OllieThemeConstants.borderRadiusMedium,
              ),
              borderSide: BorderSide(color: errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                OllieThemeConstants.borderRadiusMedium,
              ),
              borderSide: BorderSide(color: errorColor, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                OllieThemeConstants.borderRadiusMedium,
              ),
              borderSide: BorderSide(
                color: isDark
                    ? OllieThemeConstants.darkDisabled
                    : OllieThemeConstants.lightDisabled,
                width: 1.5,
              ),
            ),
            errorText: null, // Handle manually below
            counterText: '', // Hide default counter
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: OllieThemeConstants.spacingSmall),
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: errorColor),
              const SizedBox(width: OllieThemeConstants.spacingSmall),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    fontSize: OllieThemeConstants.fontSizeSmall,
                    color: errorColor,
                    fontWeight: OllieThemeConstants.fontWeightMedium,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: OllieThemeConstants.spacingSmall),
          Text(
            widget.helperText!,
            style: TextStyle(
              fontSize: OllieThemeConstants.fontSizeSmall,
              color: OllieThemeConstants.getSecondaryTextColor(brightness),
            ),
          ),
        ],
        if (widget.maxLength != null) ...[
          const SizedBox(height: OllieThemeConstants.spacingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller?.text.length ?? 0}/${widget.maxLength}',
              style: TextStyle(
                fontSize: OllieThemeConstants.fontSizeSmall,
                color: OllieThemeConstants.getSecondaryTextColor(brightness),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
