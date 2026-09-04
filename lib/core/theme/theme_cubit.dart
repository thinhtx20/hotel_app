import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit quản lý chế độ giao diện Sáng / Tối / Theo hệ thống.
/// Lưu và đồng bộ trạng thái qua SharedPreferences.
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _prefKey = 'app_theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_prefKey);
      if (modeStr == 'light') {
        emit(ThemeMode.light);
      } else if (modeStr == 'dark') {
        emit(ThemeMode.dark);
      } else {
        emit(ThemeMode.system);
      }
    } catch (_) {
      // Fallback mặc định theo hệ thống
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.light) {
        await prefs.setString(_prefKey, 'light');
      } else if (mode == ThemeMode.dark) {
        await prefs.setString(_prefKey, 'dark');
      } else {
        await prefs.setString(_prefKey, 'system');
      }
    } catch (_) {}
  }

  Future<void> toggleDarkMode(BuildContext context) async {
    final currentBrightness = Theme.of(context).brightness;
    if (state == ThemeMode.dark || (state == ThemeMode.system && currentBrightness == Brightness.dark)) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
