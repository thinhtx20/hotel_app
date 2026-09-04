import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Bảng màu ngữ nghĩa phân giải theo Brightness — xem `design/UI-REVAMP-PLAN.md` mục 3.1.
/// Widget KHÔNG bao giờ đọc AppColors trực tiếp nữa — luôn đi qua `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color canvas; // nền scaffold
  final Color surface; // nền thẻ
  final Color surfaceMuted; // nền chip, ô nhập phụ
  final Color border;
  final Color divider;
  final Color ink; // chữ chính
  final Color inkMuted; // chữ phụ
  final Color inkFaint; // placeholder / disabled
  final Color accent; // gold chính
  final Color onAccent; // chữ/icon trên nền accent
  final bool isDark;

  // ── Nhóm trạng thái (đã phân giải tương phản theo brightness) ───────
  final Color statusAvailable;
  final Color statusOccupied;
  final Color statusReserved;
  final Color statusCleaning;
  final Color statusMaintenance;

  final Color statusAvailableInk;
  final Color statusOccupiedInk;
  final Color statusReservedInk;
  final Color statusCleaningInk;
  final Color statusMaintenanceInk;

  // ── Phản hồi hệ thống ────────────────────────────────────────────────
  final Color success;
  final Color error;
  final Color warning;
  final Color info;

  final Color successSurface;
  final Color errorSurface;
  final Color warningSurface;
  final Color infoSurface;

  Color get successInk => statusAvailableInk;
  Color get errorInk => statusOccupiedInk;
  Color get warningInk => statusReservedInk;
  Color get infoInk => statusCleaningInk;

  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.divider,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.accent,
    required this.onAccent,
    required this.isDark,
    required this.statusAvailable,
    required this.statusOccupied,
    required this.statusReserved,
    required this.statusCleaning,
    required this.statusMaintenance,
    required this.statusAvailableInk,
    required this.statusOccupiedInk,
    required this.statusReservedInk,
    required this.statusCleaningInk,
    required this.statusMaintenanceInk,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.successSurface,
    required this.errorSurface,
    required this.warningSurface,
    required this.infoSurface,
  });

  /// Chế độ Sáng (Light Mode) — theo DESIGN-SYSTEM.md
  static const light = AppPalette(
    canvas: AppColors.background, // #F8FAFC
    surface: AppColors.surface, // #FFFFFF
    surfaceMuted: AppColors.surfaceMuted, // #F1F5F9
    border: AppColors.border, // #E2E8F0
    divider: AppColors.divider, // #F1F5F9
    ink: AppColors.textPrimary, // #0F172A
    inkMuted: AppColors.textSecondary, // #64748B
    inkFaint: AppColors.textMuted, // #94A3B8
    accent: AppColors.secondary, // #D97706
    onAccent: Colors.white,
    isDark: false,
    statusAvailable: AppColors.available,
    statusOccupied: AppColors.occupied,
    statusReserved: AppColors.reserved,
    statusCleaning: AppColors.cleaning,
    statusMaintenance: AppColors.maintenance,
    statusAvailableInk: AppColors.availableInk, // #047857 (tương phản ≥ 3:1)
    statusOccupiedInk: AppColors.occupiedInk, // #DC2626
    statusReservedInk: AppColors.reservedInk, // #B45309
    statusCleaningInk: AppColors.cleaningInk, // #1D4ED8
    statusMaintenanceInk: AppColors.maintenanceInk, // #4B5563
    success: AppColors.success,
    error: AppColors.error,
    warning: AppColors.warning,
    info: AppColors.info,
    successSurface: AppColors.successSurface,
    errorSurface: AppColors.errorSurface,
    warningSurface: AppColors.warningSurface,
    infoSurface: AppColors.infoSurface,
  );

  /// Chế độ Tối (Dark Mode) — theo DESIGN-SYSTEM.md
  static const dark = AppPalette(
    canvas: Color(0xFF0B1120), // sâu hơn navy 900 một bậc
    surface: AppColors.primary, // #0F172A làm mặt thẻ
    surfaceMuted: AppColors.primaryLight, // #1E293B
    border: Color(0xFF1E293B),
    divider: Color(0xFF1E293B),
    ink: Color(0xFFF1F5F9),
    inkMuted: AppColors.slate400, // #94A3B8
    inkFaint: AppColors.slate600, // #475569
    accent: AppColors.secondaryLight, // #FBBF24 — gold sáng đọc tốt trên navy
    onAccent: Color(0xFF0F172A),
    isDark: true,
    statusAvailable: AppColors.available,
    statusOccupied: AppColors.occupied,
    statusReserved: AppColors.reserved,
    statusCleaning: AppColors.cleaning,
    statusMaintenance: AppColors.maintenance,
    statusAvailableInk: AppColors.availableOnDark, // #34D399 (tương phản trên nền navy)
    statusOccupiedInk: AppColors.occupiedOnDark, // #F87171
    statusReservedInk: AppColors.reservedOnDark, // #FBBF24
    statusCleaningInk: AppColors.cleaningOnDark, // #60A5FA
    statusMaintenanceInk: AppColors.maintenanceOnDark, // #9CA3AF
    success: AppColors.availableOnDark,
    error: AppColors.occupiedOnDark,
    warning: AppColors.reservedOnDark,
    info: AppColors.cleaningOnDark,
    successSurface: Color(0xFF064E3B),
    errorSurface: Color(0xFF7F1D1D),
    warningSurface: Color(0xFF78350F),
    infoSurface: Color(0xFF1E3A8A),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? divider,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? accent,
    Color? onAccent,
    bool? isDark,
    Color? statusAvailable,
    Color? statusOccupied,
    Color? statusReserved,
    Color? statusCleaning,
    Color? statusMaintenance,
    Color? statusAvailableInk,
    Color? statusOccupiedInk,
    Color? statusReservedInk,
    Color? statusCleaningInk,
    Color? statusMaintenanceInk,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? successSurface,
    Color? errorSurface,
    Color? warningSurface,
    Color? infoSurface,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      isDark: isDark ?? this.isDark,
      statusAvailable: statusAvailable ?? this.statusAvailable,
      statusOccupied: statusOccupied ?? this.statusOccupied,
      statusReserved: statusReserved ?? this.statusReserved,
      statusCleaning: statusCleaning ?? this.statusCleaning,
      statusMaintenance: statusMaintenance ?? this.statusMaintenance,
      statusAvailableInk: statusAvailableInk ?? this.statusAvailableInk,
      statusOccupiedInk: statusOccupiedInk ?? this.statusOccupiedInk,
      statusReservedInk: statusReservedInk ?? this.statusReservedInk,
      statusCleaningInk: statusCleaningInk ?? this.statusCleaningInk,
      statusMaintenanceInk: statusMaintenanceInk ?? this.statusMaintenanceInk,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      successSurface: successSurface ?? this.successSurface,
      errorSurface: errorSurface ?? this.errorSurface,
      warningSurface: warningSurface ?? this.warningSurface,
      infoSurface: infoSurface ?? this.infoSurface,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t) ?? surfaceMuted,
      border: Color.lerp(border, other.border, t) ?? border,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t) ?? inkMuted,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t) ?? inkFaint,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      onAccent: Color.lerp(onAccent, other.onAccent, t) ?? onAccent,
      isDark: t < 0.5 ? isDark : other.isDark,
      statusAvailable: Color.lerp(statusAvailable, other.statusAvailable, t) ?? statusAvailable,
      statusOccupied: Color.lerp(statusOccupied, other.statusOccupied, t) ?? statusOccupied,
      statusReserved: Color.lerp(statusReserved, other.statusReserved, t) ?? statusReserved,
      statusCleaning: Color.lerp(statusCleaning, other.statusCleaning, t) ?? statusCleaning,
      statusMaintenance: Color.lerp(statusMaintenance, other.statusMaintenance, t) ?? statusMaintenance,
      statusAvailableInk: Color.lerp(statusAvailableInk, other.statusAvailableInk, t) ?? statusAvailableInk,
      statusOccupiedInk: Color.lerp(statusOccupiedInk, other.statusOccupiedInk, t) ?? statusOccupiedInk,
      statusReservedInk: Color.lerp(statusReservedInk, other.statusReservedInk, t) ?? statusReservedInk,
      statusCleaningInk: Color.lerp(statusCleaningInk, other.statusCleaningInk, t) ?? statusCleaningInk,
      statusMaintenanceInk: Color.lerp(statusMaintenanceInk, other.statusMaintenanceInk, t) ?? statusMaintenanceInk,
      success: Color.lerp(success, other.success, t) ?? success,
      error: Color.lerp(error, other.error, t) ?? error,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      successSurface: Color.lerp(successSurface, other.successSurface, t) ?? successSurface,
      errorSurface: Color.lerp(errorSurface, other.errorSurface, t) ?? errorSurface,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t) ?? warningSurface,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t) ?? infoSurface,
    );
  }
}

/// Tiện ích mở rộng truy cập AppPalette từ BuildContext.
extension PaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light);
}
