import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget bọc thêm hiệu ứng co lại nhẹ khi nhấn (scale 0.97) kèm rung xúc giác nhẹ.
/// Xem `design/UI-REVAMP-PLAN.md` mục 4.3.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final HitTestBehavior behavior;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap != null ? _handleTap : null,
      child: AnimatedScale(
        scale: _isPressed ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
