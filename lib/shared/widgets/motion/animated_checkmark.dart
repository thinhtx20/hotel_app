import 'dart:math';
import 'package:flutter/material.dart';

/// Hoạt ảnh dấu tick thành công vẽ dần chuẩn Modern Luxury.
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final VoidCallback? onComplete;

  const AnimatedCheckmark({
    super.key,
    this.size = 72,
    this.color = const Color(0xFF10B981),
    this.onComplete,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _circleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CheckmarkPainter(
              circleProgress: _circleAnimation.value,
              checkProgress: _checkAnimation.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  _CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Paint cho vòng tròn
    final circlePaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (circleProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * circleProgress,
        false,
        circlePaint,
      );
    }

    // Paint cho dấu check
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final p1 = Offset(size.width * 0.28, size.height * 0.52);
      final p2 = Offset(size.width * 0.44, size.height * 0.68);
      final p3 = Offset(size.width * 0.74, size.height * 0.36);

      final path = Path();
      if (checkProgress <= 0.4) {
        final t = checkProgress / 0.4;
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );
      } else {
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
        final t = (checkProgress - 0.4) / 0.6;
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * t,
          p2.dy + (p3.dy - p2.dy) * t,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
        oldDelegate.checkProgress != checkProgress ||
        oldDelegate.color != color;
  }
}
