import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import 'app_palette.dart';

/// Chủ đề Modern Luxury — xem `design/DESIGN-SYSTEM.md` và `design/UI-REVAMP-PLAN.md`.
class AppTheme {
  /// Chủ đề Sáng (Light Theme)
  static ThemeData get lightTheme =>
      _baseTheme(AppPalette.light, Brightness.light);

  /// Chủ đề Tối (Dark Theme)
  static ThemeData get darkTheme =>
      _baseTheme(AppPalette.dark, Brightness.dark);

  static ThemeData _baseTheme(AppPalette palette, Brightness brightness) {
    final base = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: palette.canvas,
      extensions: [palette],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: palette.accent,
        onSecondary: palette.onAccent,
        surface: palette.surface,
        onSurface: palette.ink,
        error: palette.error,
        onError: Colors.white,
        outline: palette.border,
      ),
      textTheme: _textTheme(base, palette),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.dark ? palette.canvas : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardR),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: _fieldBorder(palette.border),
        enabledBorder: _fieldBorder(palette.border),
        focusedBorder: _fieldBorder(palette.accent, width: 2),
        errorBorder: _fieldBorder(palette.error),
        focusedErrorBorder: _fieldBorder(palette.error, width: 2),
        labelStyle: TextStyle(color: palette.inkMuted),
        floatingLabelStyle: TextStyle(
          color: palette.accent,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: palette.inkFaint),
        prefixIconColor: palette.inkMuted,
        suffixIconColor: palette.inkMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.border,
          disabledForegroundColor: palette.inkFaint,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonR),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size(0, 52),
          side: BorderSide(color: palette.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonR),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          textStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceMuted,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillR),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: palette.inkMuted,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: palette.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle:
            GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        elevation: 0,
        height: 72,
        indicatorColor: palette.accent.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.pillR),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? palette.accent : palette.inkFaint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? palette.accent : palette.inkFaint,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetR),
        showDragHandle: false,
        dragHandleColor: palette.border,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardR),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark ? palette.surfaceMuted : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonR),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.surfaceMuted,
        circularTrackColor: palette.surfaceMuted,
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.buttonR,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Thang chữ: Display 32 · Tiêu đề màn 24 · Tiêu đề mục 18 · Thẻ 16
  /// · Nội dung 14 · Phụ 13 · Nhãn nhỏ 11.
  static TextTheme _textTheme(TextTheme base, AppPalette palette) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: palette.ink,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: palette.ink,
        letterSpacing: -0.5,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: palette.ink,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: palette.ink,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: palette.ink,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15,
        color: palette.ink,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        color: palette.inkMuted,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        color: palette.inkMuted,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: palette.inkFaint,
        letterSpacing: 0.5,
      ),
    );
  }
}
