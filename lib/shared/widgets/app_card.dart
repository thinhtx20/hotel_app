import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import 'motion/pressable_scale.dart';

/// Thẻ chuẩn Modern Luxury — xem `design/DESIGN-SYSTEM.md`.
/// Bo góc 20, bóng khuếch tán soft, nền theo context.palette.surface, tự thu 0.98 khi chạm.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double borderRadius;
  final List<BoxShadow>? shadows;
  final Border? border;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.color,
    this.borderRadius = AppRadius.card,
    this.shadows,
    this.border,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final effectiveBorder = border ??
        (hasBorder || palette.isDark
            ? Border.all(color: palette.border, width: 1)
            : null);

    final cardContent = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: palette.isDark ? null : (shadows ?? AppShadows.soft),
        border: effectiveBorder,
      ),
      child: child,
    );

    if (onTap != null) {
      return PressableScale(
        onTap: onTap,
        scale: 0.98,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
