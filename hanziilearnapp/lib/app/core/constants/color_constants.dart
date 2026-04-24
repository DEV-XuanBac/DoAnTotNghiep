import 'package:flutter/material.dart';

/// Màu sắc dùng trong app.
class AppColors {
  AppColors._();
  static bool _isDarkMode = false;

  static void setDarkMode(bool value) {
    _isDarkMode = value;
  }

  static Color _pick(Color light, Color dark) => _isDarkMode ? dark : light;

  static Color get backgroundLight =>
      _pick(const Color(0xFFE0FFFF), const Color(0xFF0F1D2B));
  static Color get backgroundDark =>
      _pick(const Color(0xFFE5E4E2), const Color(0xFF0B1622));
  static Color get backgroundWhite =>
      _pick(const Color(0xFFFFFFFF), const Color(0xFF152332));
  static Color get backgroundGradientStart =>
      _pick(const Color(0xFFA3FEBA), const Color(0xFF1E5A6E));
  static Color get backgroundGradientEnd =>
      _pick(const Color(0xFF72FE95), const Color(0xFF224E84));

  static Color get bottomNavBarBackground =>
      _pick(const Color(0xFFCCFFFF), const Color(0xFF1A2A3A));
  static Color get selectedItemBottomNavBar =>
      _pick(const Color(0xFFFFFFFF), const Color(0xFF2C3F52));
  static Color get unselectedItemBottomNavBar =>
      _pick(const Color(0xFF59955C), const Color(0xFF8FA7BC));

  static Color get darkCardBackground =>
      _pick(const Color(0xFFE9F1EA), const Color(0xFF1B2A3B));
  static Color get lightCardBackground =>
      _pick(const Color(0xFFADD8E6), const Color(0xFF213549));
  static Color get cardPersonal =>
      _pick(const Color(0xFFC2DFFF), const Color(0xFF1D3044));
  static Color get cardItem => _pick(const Color(0xFF79BAEC), const Color(0xFF2E4E69));
  static Color get cardDailyOnline =>
      _pick(const Color(0xFF1589FF), const Color(0xFF4BA3FF));
  static Color get cardDailyOffline =>
      _pick(const Color(0xFFA8A9AD), const Color(0xFF738395));
  static Color get toggleBackgrouund =>
      _pick(const Color(0xFFC0E0DA), const Color(0xFF274159));
  static Color get toggleSelected =>
      _pick(const Color(0xFF1F88A7), const Color(0xFF45B3D8));
  static Color get whiteCard => _pick(const Color(0xFFFCF6F5), const Color(0xFF1A2B3C));
  static Color get greenCard => _pick(const Color(0xFF4AA02C), const Color(0xFF56BB69));
  static Color get darkGreenCard =>
      _pick(const Color(0xFF045D5D), const Color(0xFF2A8B8B));
  static Color get darkBlueCard =>
      _pick(const Color(0xFF007C80), const Color(0xFF4B97BF));

  static Color get label => _pick(const Color(0xFF123456), const Color(0xFFDCF3FF));
  static Color get labelOnboarding =>
      _pick(const Color(0xFF48FB0D), const Color(0xFF9AFB8D));
  static Color get primaryText => _pick(const Color(0xFF000000), const Color(0xFFE8F1F8));
  static Color get lightBlackText =>
      _pick(const Color(0xFF040720), const Color(0xFFD1E3F2));
  static Color get whiteText => const Color(0xFFFFFFFF);
  static Color get secondaryText =>
      _pick(const Color(0xFF454545), const Color(0xFFB8CADB));
  static Color get blueDarkText =>
      _pick(const Color(0xFF2B60DE), const Color(0xFF77B4FF));
  static Color get greenText => _pick(const Color(0xFF1FCB4A), const Color(0xFF74D68E));
  static Color get favourText => _pick(const Color(0xFFF70D1A), const Color(0xFFFF6B74));
  static Color get vocabDarkText =>
      _pick(const Color(0xFF0000A5), const Color(0xFF90A8FF));
  static Color get errorText => _pick(const Color(0xFFFF0000), const Color(0xFFFF7B7B));

  static Color get bottomButton =>
      _pick(const Color(0xFF52595D), const Color(0xFFB5CADB));
  static Color get toolButton => _pick(const Color(0xFF43BFC7), const Color(0xFF5AC7E0));
  static Color get talkButton => _pick(const Color(0xFF1E90FF), const Color(0xFF66B7FF));
  static Color get historyButton =>
      _pick(const Color(0xFFADD8E6), const Color(0xFF345067));
  static Color get vocabularyButton =>
      _pick(const Color(0xFF3090C7), const Color(0xFF4B9DD1));

  static Color get borderDefault =>
      _pick(const Color(0xFF98AFC7), const Color(0xFF47627A));
  static Color get borderEnable => _pick(const Color(0xFF2F539B), const Color(0xFF80A6EA));
  static Color get borderFocus => _pick(const Color(0xFF1F45FC), const Color(0xFF7BA2FF));
}
