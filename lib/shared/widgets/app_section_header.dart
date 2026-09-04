import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import 'motion/pressable_scale.dart';

/// Tiêu đề mục chuẩn Modern Luxury — xem `design/DESIGN-SYSTEM.md`.
/// Cỡ 18 / w600 với nút hành động tùy chọn ("Xem tất cả").
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionTitle;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionTitle,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (actionTitle != null && onAction != null)
            PressableScale(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionTitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: palette.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
