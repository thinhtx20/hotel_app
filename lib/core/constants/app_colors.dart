import 'package:flutter/material.dart';

/// Bảng màu Modern Luxury — xem `design/DESIGN-SYSTEM.md`.
///
/// Bộ màu trạng thái được chia làm 3 nhóm có mục đích riêng, đã kiểm chứng
/// bằng validator mù màu + tương phản:
///  * [statusFill]     — màu tô (ô phòng, đoạn biểu đồ, chấm chú thích)
///  * [statusInk]      — màu chữ trên nền sáng (đạt tương phản ≥ 3:1)
///  * [statusOnDark]   — màu trên nền navy
///
/// Trạng thái KHÔNG BAO GIỜ chỉ thể hiện bằng màu — luôn kèm nhãn chữ.
class AppColors {
  // ── Thương hiệu ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F172A); // Navy 900
  static const Color primaryLight = Color(0xFF1E293B); // Navy 800
  static const Color secondary = Color(0xFFD97706); // Gold
  static const Color secondaryLight = Color(0xFFFBBF24); // Gold sáng
  static const Color secondaryDark = Color(0xFFB45309); // Gold đậm

  // ── Nền & bề mặt ───────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9); // nền chip, ô nhập phụ
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // ── Chữ ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // ── Trạng thái phòng: MÀU TÔ (đạt kiểm tra mù màu, ΔE 8.1 deutan) ──────
  static const Color available = Color(0xFF10B981);
  static const Color occupied = Color(0xFFEF4444);
  static const Color reserved = Color(0xFFF59E0B);
  static const Color cleaning = Color(0xFF3B82F6);
  static const Color maintenance = Color(0xFF6B7280);

  // ── Trạng thái phòng: MÀU CHỮ trên nền sáng (đạt tương phản ≥ 3:1) ─────
  // Không dùng nhóm này làm màu tô cạnh nhau: cặp reservedInk ↔ occupiedInk
  // chỉ đạt ΔE 2.8 dưới mắt mù màu deutan.
  static const Color availableInk = Color(0xFF047857);
  static const Color occupiedInk = Color(0xFFDC2626);
  static const Color reservedInk = Color(0xFFB45309);
  static const Color cleaningInk = Color(0xFF1D4ED8);
  static const Color maintenanceInk = Color(0xFF4B5563);

  // ── Trạng thái phòng: trên nền navy ────────────────────────────────────
  static const Color availableOnDark = Color(0xFF34D399);
  static const Color occupiedOnDark = Color(0xFFF87171);
  static const Color reservedOnDark = Color(0xFFFBBF24);
  static const Color cleaningOnDark = Color(0xFF60A5FA);
  static const Color maintenanceOnDark = Color(0xFF9CA3AF);

  // ── Phản hồi hệ thống & Utitilies ──────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color successInk = Color(0xFF047857);
  static const Color errorInk = Color(0xFFDC2626);
  static const Color warningInk = Color(0xFFB45309);
  static const Color infoInk = Color(0xFF1D4ED8);

  static const Color successSurface = Color(0xFFECFDF5);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color infoSurface = Color(0xFFEFF6FF);

  // ── Color Aliases ──────────────────────────────────────────────────────
  static const Color navy = Color(0xFF0F172A);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFB45309);
  static const Color rose = Color(0xFFEF4444);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate900 = Color(0xFF0F172A);
}

/// Gradient dùng chung. Hướng chéo 135° cho toàn bộ hệ thống.
class AppGradients {
  static const LinearGradient navy = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gold = LinearGradient(
    colors: [AppColors.secondary, AppColors.secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Phủ lên ảnh để chữ trắng đọc rõ: trong suốt ở đỉnh → navy ở đáy.
  static LinearGradient get imageScrim => LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.45),
          AppColors.primary.withValues(alpha: 0.85),
        ],
        stops: const [0.35, 0.7, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  /// Vùng tô dưới đường biểu đồ doanh thu.
  static LinearGradient get chartArea => LinearGradient(
        colors: [
          AppColors.secondary.withValues(alpha: 0.22),
          AppColors.secondary.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
