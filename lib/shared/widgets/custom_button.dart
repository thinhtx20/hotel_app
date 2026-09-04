import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import 'motion/pressable_scale.dart';

/// Nút bấm chuẩn Modern Luxury — xem `design/DESIGN-SYSTEM.md` và `design/UI-REVAMP-PLAN.md` mục 4.4.
/// - Đổ bóng chuẩn [AppShadows.goldGlow]
/// - Rung xúc giác + co nhẹ [PressableScale]
/// - Hiệu ứng morphing co gọn khi đang tải [isLoading]
/// - Tự điều chỉnh màu theo [AppPalette]
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final Widget? leading;
  final double height;
  final double borderRadius;
  final bool isGold;
  final Gradient? gradient;
  final bool hasShadow;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.leading,
    this.height = 52,
    this.borderRadius = AppRadius.button,
    this.isGold = true,
    this.gradient,
    this.hasShadow = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final effectiveGradient =
        gradient ??
        (isGold
            ? AppGradients.gold
            : (backgroundColor == null ? AppGradients.navy : null));

    final effectiveColor = effectiveGradient == null
        ? (backgroundColor ??
              (palette.isDark ? palette.surfaceMuted : AppColors.primary))
        : null;

    final glowShadow = hasShadow && onPressed != null && !isLoading
        ? (isGold
              ? AppShadows.goldGlow
              : (palette.isDark ? null : AppShadows.navyGlow))
        : null;

    final effectiveTextColor =
        textColor ??
        (isGold
            ? (palette.isDark ? AppColors.navy : Colors.white)
            : Colors.white);

    // Khi isLoading == true, nút morph co lại thành hình tròn đường kính [height]
    final isMorphing = isLoading;

    return Center(
      // [SizedBox] chốt cứng chiều cao để nút trả lời được truy vấn intrinsic
      // height (ví dụ khi nằm trong SliverFillRemaining(hasScrollBody: false)
      // hay IntrinsicHeight) mà không phải chạy xuống [LayoutBuilder] bên dưới
      // — LayoutBuilder không hỗ trợ intrinsic và sẽ ném assertion.
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // AnimatedContainer không nội suy được giữa width hữu hạn và
            // double.infinity (BoxConstraints.lerp sẽ assert khi morph sang
            // trạng thái loading), nên quy đổi "full width" thành số đo thật.
            // Nếu cha không giới hạn bề ngang thì để null cho nút tự co theo nội dung.
            final double? fullWidth =
                width ??
                (constraints.maxWidth.isFinite ? constraints.maxWidth : null);
            final double? targetWidth = isMorphing ? height : fullWidth;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: AppMotion.enter,
              width: targetWidth,
              height: height,
              decoration: BoxDecoration(
                color: effectiveColor,
                gradient: effectiveGradient,
                borderRadius: BorderRadius.circular(
                  isMorphing ? height / 2 : borderRadius,
                ),
                boxShadow: glowShadow,
              ),
              child: PressableScale(
                onTap: isLoading ? null : onPressed,
                scale: 0.97,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      isMorphing ? height / 2 : borderRadius,
                    ),
                    onTap: isLoading ? null : onPressed,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isLoading
                            ? SizedBox(
                                key: const ValueKey('button_loading'),
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    effectiveTextColor,
                                  ),
                                ),
                              )
                            : Row(
                                key: const ValueKey('button_content'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (leading != null) ...[
                                    leading!,
                                    const SizedBox(width: AppSpacing.sm),
                                  ] else if (icon != null) ...[
                                    Icon(
                                      icon,
                                      size: 20,
                                      color: effectiveTextColor,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                  ],
                                  Flexible(
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: effectiveTextColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
