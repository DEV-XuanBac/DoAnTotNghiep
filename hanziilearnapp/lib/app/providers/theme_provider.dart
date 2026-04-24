import 'package:flutter/material.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeModeKey = 'app.theme.mode.dark';

  ThemeProvider() {
    _loadThemeMode();
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeModeKey) ?? false;
    AppColors.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) {
      return;
    }
    _isDarkMode = value;
    AppColors.setDarkMode(value);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, value);
  }
}
