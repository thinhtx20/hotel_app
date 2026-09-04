import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// Ô tìm kiếm chuẩn Modern Luxury tái sử dụng ở Home, Search, Cashier.
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;

  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Tìm kiếm...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      autofocus: autofocus,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 14,
        color: palette.ink,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: palette.inkFaint,
        ),
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: palette.inkMuted,
        ),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear_rounded, size: 18, color: palette.inkMuted),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                  onChanged?.call('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: AppRadius.buttonR,
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonR,
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonR,
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
    );
  }
}
