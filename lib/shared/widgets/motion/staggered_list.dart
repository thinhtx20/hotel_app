import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_dimens.dart';

/// Widget hỗ trợ hoạt ảnh xuất hiện so le (staggered entrance) cho danh sách.
/// Tự động chặn tối đa ở [AppMotion.staggerMaxItems] (12 items) để tránh giật trên danh sách dài.
class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration? duration;
  final double slideOffset;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration,
    this.slideOffset = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    if (index >= AppMotion.staggerMaxItems) {
      return child;
    }

    final delay = AppMotion.stagger * index;
    final animDuration = duration ?? const Duration(milliseconds: 250);

    return child
        .animate(delay: delay)
        .fadeIn(duration: animDuration, curve: AppMotion.enter)
        .slideY(begin: slideOffset, end: 0, duration: animDuration, curve: AppMotion.enter);
  }
}

/// Helper bọc toàn bộ danh sách children bằng StaggeredListItem
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          StaggeredListItem(index: i, child: children[i]),
          if (spacing > 0 && i < children.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}
