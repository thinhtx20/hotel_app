import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';

/// Nguyên thủy Shimmer Skeleton — tự động đổi màu theo AppPalette sáng / tối.
/// Trên nền tối: shimmer sáng lên, không tối đi (theo DESIGN-SYSTEM.md nguyên tắc #6).
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final ShapeBorder? shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppRadius.button,
    this.shape,
  });

  const SkeletonBox.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 999,
        shape = const CircleBorder();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final baseColor = palette.isDark
        ? palette.surfaceMuted
        : const Color(0xFFE2E8F0);

    final highlightColor = palette.isDark
        ? const Color(0xFF334155) // Navy sáng hơn để shimmer nổi bật
        : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: AppDurations.shimmer,
      child: Container(
        width: width,
        height: height,
        decoration: shape != null
            ? ShapeDecoration(color: baseColor, shape: shape!)
            : BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
      ),
    );
  }
}

/// Thanh Skeleton giả lập chữ text
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonText({
    super.key,
    required this.width,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: 4,
    );
  }
}
