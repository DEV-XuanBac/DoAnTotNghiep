import 'package:flutter/material.dart';

/// Các màu sắc dùng trong app - tập trung tại đây để dễ bảo trì
class AppColors {
  AppColors._();

  //Background
  static const Color backgroundLight = Color(0xFFE0FFFF);
  static const Color backgroundDark = Color(0xFFE5E4E2);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGradientStart = Color(0xFFA3FEBA);
  static const Color backgroundGradientEnd = Color(0xFF72FE95);

  // Bottom Navigation Bar
  static const Color bottomNavBarBackground = Color(0xFFCCFFFF);
  static const Color selectedItemBottomNavBar = Color(0xFFFFFFFF);
  static const Color unselectedItemBottomNavBar = Color(0xFF59955C);

  // Cards
  static const Color darkCardBackground = Color(0xFFE9F1EA);
  static const Color lightCardBackground = Color(0xFFADD8E6);
  static const Color cardPersonal = Color(0xFFC2DFFF);
  static const Color cardItem = Color(0xFF79BAEC);
  static const Color cardDailyOnline = Color(0xFF1589FF);
  static const Color cardDailyOffline = Color(0xFFA8A9AD);
  static const Color toggleBackgrouund = Color(0xFFC0E0DA);
  static const Color toggleSelected = Color(0xFF1F88A7);
  static const Color whiteCard = Color(0xFFFCF6F5);

  // Text
  static const Color label = Color(0xFF123456);
  static const Color labelOnboarding = Color(0xFF48FB0D);
  static const Color primaryText = Color(0xFF000000);
  static const Color lightBlackText = Color(0xFF040720);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFF454545);
  static const Color blueDarkText = Color(0xFF2B60DE);
  static const Color vocabDarkText = Color(0xFF0000A5);
  static const Color errorText = Color(0xFFFF0000);

  // Buttons
  static const Color bottomButton = Color(0xFF52595D);
  static const Color toolButton = Color(0xFF43BFC7);
  static const Color talkButton = Color(0xFF1E90FF);
  static const Color historyButton = Color(0xFFADD8E6);
  static const Color vocabularyButton = Color(0xFF3090C7);

  // Borders
  static const Color borderDefault = Color(0xFF98AFC7);
  static const Color borderEnable = Color(0xFF2F539B);
  static const Color borderFocus = Color(0xFF1F45FC);
}
