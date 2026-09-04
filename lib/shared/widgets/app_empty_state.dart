import 'package:flutter/material.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import 'custom_button.dart';

/// Trạng thái rỗng chuẩn Modern Luxury — xem `design/DESIGN-SYSTEM.md` nguyên tắc #5:
/// "Minh họa + một câu giải thích + một nút hành động — thay 5 bản copy-paste".
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customIllustration;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minh họa hoặc icon trong vòng tròn Frosted Glass
            customIllustration ??
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.border, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 40,
                      color: palette.accent.withValues(alpha: 0.85),
                    ),
                  ),
                ),
            const SizedBox(height: AppSpacing.xl),

            // Tiêu đề
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Giải thích
            Text(
              description,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: palette.inkMuted,
                height: 1.4,
              ),
            ),

            // Nút hành động
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              CustomButton(
                text: actionText!,
                onPressed: onAction,
                height: 46,
                isGold: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
