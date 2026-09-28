import 'package:flutter/material.dart';

import '../core/utils/session_manager.dart';

/// Bonus 5.3 - Dark Mode / Light Mode dengan preferensi disimpan di SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Wajib dipanggil sekali saat aplikasi start (lihat main.dart).
  Future<void> loadThemeFromPrefs() async {
    final isDark = await SessionManager.getDarkMode();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await SessionManager.setDarkMode(isDark);
    notifyListeners();
  }
}
