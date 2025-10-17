import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  }) : keyboardType = TextInputType.text,
       obscureText = false,
       prefixIcon = null,
       suffixIcon = null,
       inputFormatters = null,
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
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: Colors.grey.shade600,
        ),
        onPressed: _togglePasswordVisibility,
      );
    }
    return widget.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasError ? Colors.red.shade700 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
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
            fontSize: 16,
            color: widget.enabled ? Colors.black87 : Colors.grey.shade500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: hasError
                        ? Colors.red.shade700
                        : _focusNode.hasFocus
                        ? Colors.blue
                        : Colors.grey.shade600,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
            filled: true,
            fillColor: widget.enabled
                ? (hasError
                      ? Colors.red.shade50
                      : _focusNode.hasFocus
                      ? Colors.blue.shade50
                      : Colors.grey.shade50)
                : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade300 : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade700 : Colors.blue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade700, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            errorText: null, // Handle manually below
            counterText: '', // Hide default counter
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
        if (widget.maxLength != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller?.text.length ?? 0}/${widget.maxLength}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ],
    );
  }
}
