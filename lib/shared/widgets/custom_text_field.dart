import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// Ô nhập liệu chuẩn Modern Luxury — xem `design/UI-REVAMP-PLAN.md` mục 4.4.
/// - Viền focus chuyển màu mượt mà
/// - Icon đổi màu đồng bộ theo trạng thái focus
/// - Tự động đồng bộ màu theo AppPalette (sáng/tối)
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 15,
        color: palette.ink,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        prefixIcon: widget.prefixIcon != null
            ? AnimatedTheme(
                data: Theme.of(context),
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.prefixIcon,
                  size: 20,
                  color: _isFocused ? palette.accent : palette.inkMuted,
                ),
              )
            : null,
        suffixIcon: widget.suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: palette.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: palette.error, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Outfit',
          color: _isFocused ? palette.accent : palette.inkMuted,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: 'Outfit',
          color: palette.accent,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Outfit',
          color: palette.inkFaint,
          fontSize: 14,
        ),
      ),
    );
  }
}
