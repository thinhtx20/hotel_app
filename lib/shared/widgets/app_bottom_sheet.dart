import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// Khung vỏ Bottom Sheet chuẩn Modern Luxury — xem `design/DESIGN-SYSTEM.md`.
/// Có drag handle, bo góc trên 28px, nền mờ và an toàn theo bàn phím.
class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool showDragHandle;
  final double? maxHeight;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding,
    this.showDragHandle = true,
    this.maxHeight,
  });

  /// Phương thức tĩnh mở bottom sheet với cấu hình chuẩn
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final content = Container(
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight!)
          : BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.sheetR,
        boxShadow: palette.isDark ? null : AppShadows.medium,
        border: palette.isDark ? Border.all(color: palette.border, width: 1) : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.lg,
                  AppSpacing.screen,
                  AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: textTheme.titleLarge?.copyWith(
                          color: palette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
              Divider(color: palette.divider, height: 1),
            ],
            Flexible(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(AppSpacing.screen),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    return content;
  }
}
