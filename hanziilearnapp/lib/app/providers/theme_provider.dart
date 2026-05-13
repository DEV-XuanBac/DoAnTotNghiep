import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persist & expose theme preference (`light` / `dark`) cho [MaterialApp].
///
/// Provider này **không** đụng đến token màu — toàn bộ màu được lấy qua
/// `context.palette` (`AppPalette` ThemeExtension), Flutter sẽ tự rebuild khi
/// [themeMode] thay đổi.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    unawaited(_loadThemeMode());
  }

  static const _themeModeKey = 'app.theme.mode.dark';

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) {
      return;
    }
    _isDarkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, value);
  }
}
