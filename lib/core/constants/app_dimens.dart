import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Thang khoảng cách bội số 4 — xem `design/DESIGN-SYSTEM.md`.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Lề trái/phải mặc định của mọi màn hình.
  static const double screen = 20;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: screen);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}

/// Bán kính bo góc.
class AppRadius {
  static const double card = 20;
  static const double cardSmall = 16;
  static const double button = 12;
  static const double field = 12;
  static const double image = 16;
  static const double sheet = 28;
  static const double pill = 999;

  static BorderRadius get cardR => BorderRadius.circular(card);
  static BorderRadius get cardSmallR => BorderRadius.circular(cardSmall);
  static BorderRadius get buttonR => BorderRadius.circular(button);
  static BorderRadius get imageR => BorderRadius.circular(image);
  static BorderRadius get pillR => BorderRadius.circular(pill);
  static BorderRadius get sheetR =>
      const BorderRadius.vertical(top: Radius.circular(sheet));
}

/// Đổ bóng — khuếch tán và rất nhẹ. Ưu tiên bóng hơn đường viền.
class AppShadows {
  /// Thẻ thường.
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  /// Thẻ nổi, bottom sheet, thanh điều hướng.
  static List<BoxShadow> get medium => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Quầng sáng dưới nút hành động chính.
  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Quầng sáng dưới khối navy (logo, nút phụ).
  static List<BoxShadow> get navyGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Thời lượng hoạt ảnh.
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration shimmer = Duration(milliseconds: 1200);
}
