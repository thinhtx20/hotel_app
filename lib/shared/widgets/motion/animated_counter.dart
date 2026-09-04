import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';

/// Hoạt ảnh đếm số từ 0 lên giá trị đích dành cho các chỉ số Dashboard.
class AnimatedCounter extends StatelessWidget {
  final num targetValue;
  final String Function(num value) formatter;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.targetValue,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.curve = AppMotion.enter,
  });

  /// Đếm số nguyên đơn giản (ví dụ: 12 đơn, 4 khách)
  factory AnimatedCounter.integer({
    Key? key,
    required int value,
    TextStyle? style,
    String suffix = '',
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return AnimatedCounter(
      key: key,
      targetValue: value,
      formatter: (v) => '${v.toInt()}$suffix',
      style: style,
      duration: duration,
    );
  }

  /// Đếm phần trăm (ví dụ: 85%)
  factory AnimatedCounter.percent({
    Key? key,
    required double percent,
    TextStyle? style,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    return AnimatedCounter(
      key: key,
      targetValue: percent,
      formatter: (v) {
        final d = v.toDouble();
        return d % 1 == 0 ? '${d.toInt()}%' : '${d.toStringAsFixed(1)}%';
      },
      style: style,
      duration: duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: targetValue.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Text(
          formatter(value),
          style: style,
        );
      },
    );
  }
}
