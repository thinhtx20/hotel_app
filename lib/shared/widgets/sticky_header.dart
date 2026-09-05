import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// Ghim một dải nội dung (thanh lọc, tiêu đề nhóm...) lên đỉnh vùng cuộn.
///
/// Đặt trong `CustomScrollView`, ngay sau phần cuộn được. Khi phần đó trôi khỏi
/// màn, dải này dừng lại ở đỉnh thay vì trôi theo — đổi bộ lọc hay biết mình
/// đang xem nhóm nào mà không phải cuộn ngược lên.
///
/// [contentHeight] phải khớp chiều cao thật của [child]: sliver ghim cần biết
/// trước kích thước nên mọi thành phần con phải cao cố định (bọc ô tìm kiếm
/// trong `SizedBox`/`Container` có `height`).
///
/// [topInset] dành cho màn **không có AppBar** — `CustomScrollView` khi đó chạy
/// sát mép trên, dải ghim phải tự chừa chiều cao status bar; truyền
/// `MediaQuery.paddingOf(context).top`. Màn đã có `SliverAppBar(pinned: true)`
/// thì để mặc định 0 vì dải ghim nằm ngay dưới app bar.
///
/// Nhiều dải ghim liên tiếp: bọc mỗi nhóm trong `SliverMainAxisGroup` để tiêu
/// đề nhóm sau đẩy tiêu đề nhóm trước đi thay vì chồng lên nhau.
class SliverStickyHeader extends StatelessWidget {
  const SliverStickyHeader({
    super.key,
    required this.contentHeight,
    required this.child,
    this.topInset = 0,
    this.topGap = AppSpacing.md,
    this.bottomGap = AppSpacing.lg,
  });

  /// Chiều cao cố định của [child].
  final double contentHeight;

  /// Nội dung dải ghim — dựng ở `build` của màn để giữ controller/focus.
  final Widget child;

  /// Chiều cao status bar, chỉ chèn vào khi dải đã dính lên đỉnh.
  final double topInset;

  /// Khoảng cách với khối phía trên lúc chưa dính.
  final double topGap;

  /// Khoảng cách với item đầu tiên của danh sách lúc chưa dính.
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(
        contentHeight: contentHeight,
        topInset: topInset,
        topGap: topGap,
        bottomGap: bottomGap,
        child: child,
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyHeaderDelegate({
    required this.contentHeight,
    required this.topInset,
    required this.topGap,
    required this.bottomGap,
    required this.child,
  });

  final double contentHeight;
  final double topInset;
  final double topGap;
  final double bottomGap;
  final Widget child;

  /// Viền dưới lúc đã dính. `BoxDecoration.border` chiếm chỗ thật trong layout
  /// nên phải cộng vào extent, nếu không [child] bị ép thấp đi đúng 1px và tràn.
  static const double _dividerHeight = 1;

  @override
  double get minExtent => topInset + contentHeight + _dividerHeight;

  /// `math.max` phòng khi status bar cao hơn cả hai khoảng đệm cộng lại —
  /// sliver yêu cầu maxExtent >= minExtent.
  @override
  double get maxExtent =>
      math.max(minExtent, topGap + contentHeight + bottomGap + _dividerHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final palette = context.palette;
    final range = maxExtent - minExtent;
    // 0 khi còn nằm dưới header, 1 khi đã dính hẳn lên đỉnh.
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final isStuck = shrinkOffset > 0;

    return Container(
      // Nền đục để nội dung cuộn xuống dưới không lộ ra.
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(
          bottom: BorderSide(
            color: isStuck ? palette.border : Colors.transparent,
            width: _dividerHeight,
          ),
        ),
        boxShadow: isStuck
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: palette.isDark ? 0.5 : 0.07,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      // Đệm trên nội suy từ `topGap` (chưa dính) sang `topInset` (đã dính).
      padding: EdgeInsets.only(top: topGap + (topInset - topGap) * t),
      // Chỗ trống thừa lúc chưa dính rơi xuống đáy — chính là `bottomGap`.
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.contentHeight != contentHeight ||
      oldDelegate.topInset != topInset ||
      oldDelegate.topGap != topGap ||
      oldDelegate.bottomGap != bottomGap;
}
