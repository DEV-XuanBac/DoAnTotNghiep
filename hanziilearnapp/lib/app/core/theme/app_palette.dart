import 'package:flutter/material.dart';

/// Bảng màu của app 
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.backgroundLight,
    required this.backgroundDark,
    required this.backgroundWhite,
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
    required this.bottomNavBarBackground,
    required this.selectedItemBottomNavBar,
    required this.unselectedItemBottomNavBar,
    required this.darkCardBackground,
    required this.lightCardBackground,
    required this.cardPersonal,
    required this.cardItem,
    required this.cardDailyOnline,
    required this.cardDailyOffline,
    required this.toggleBg,
    required this.toggleSelected,
    required this.whiteCard,
    required this.greenCard,
    required this.darkGreenCard,
    required this.darkBlueCard,
    required this.label,
    required this.labelOnboarding,
    required this.primaryText,
    required this.lightBlackText,
    required this.whiteText,
    required this.secondaryText,
    required this.blueDarkText,
    required this.greenText,
    required this.favourText,
    required this.vocabDarkText,
    required this.errorText,
    required this.bottomButton,
    required this.toolButton,
    required this.talkButton,
    required this.historyButton,
    required this.vocabularyButton,
    required this.borderDefault,
    required this.borderEnable,
    required this.borderFocus,
  });

  final Color backgroundLight;
  final Color backgroundDark;
  final Color backgroundWhite;
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;

  final Color bottomNavBarBackground;
  final Color selectedItemBottomNavBar;
  final Color unselectedItemBottomNavBar;

  final Color darkCardBackground;
  final Color lightCardBackground;
  final Color cardPersonal;
  final Color cardItem;
  final Color cardDailyOnline;
  final Color cardDailyOffline;
  final Color toggleBg;
  final Color toggleSelected;
  final Color whiteCard;
  final Color greenCard;
  final Color darkGreenCard;
  final Color darkBlueCard;

  final Color label;
  final Color labelOnboarding;
  final Color primaryText;
  final Color lightBlackText;
  final Color whiteText;
  final Color secondaryText;
  final Color blueDarkText;
  final Color greenText;
  final Color favourText;
  final Color vocabDarkText;
  final Color errorText;

  final Color bottomButton;
  final Color toolButton;
  final Color talkButton;
  final Color historyButton;
  final Color vocabularyButton;

  final Color borderDefault;
  final Color borderEnable;
  final Color borderFocus;

  /// Bảng màu light theme.
  static const AppPalette light = AppPalette(
    backgroundLight: Color(0xFFE0FFFF),
    backgroundDark: Color(0xFFE5E4E2),
    backgroundWhite: Color(0xFFFFFFFF),
    backgroundGradientStart: Color(0xFFA3FEBA),
    backgroundGradientEnd: Color(0xFF72FE95),
    bottomNavBarBackground: Color(0xFFCCFFFF),
    selectedItemBottomNavBar: Color(0xFFFFFFFF),
    unselectedItemBottomNavBar: Color(0xFF59955C),
    darkCardBackground: Color(0xFFE9F1EA),
    lightCardBackground: Color(0xFFADD8E6),
    cardPersonal: Color(0xFFC2DFFF),
    cardItem: Color(0xFF79BAEC),
    cardDailyOnline: Color(0xFF1589FF),
    cardDailyOffline: Color(0xFFA8A9AD),
    toggleBg: Color(0xFFC0E0DA),
    toggleSelected: Color(0xFF1F88A7),
    whiteCard: Color(0xFFFCF6F5),
    greenCard: Color(0xFF4AA02C),
    darkGreenCard: Color(0xFF045D5D),
    darkBlueCard: Color(0xFF007C80),
    label: Color(0xFF123456),
    labelOnboarding: Color(0xFF48FB0D),
    primaryText: Color(0xFF000000),
    lightBlackText: Color(0xFF040720),
    whiteText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFF454545),
    blueDarkText: Color(0xFF2B60DE),
    greenText: Color(0xFF1FCB4A),
    favourText: Color(0xFFF70D1A),
    vocabDarkText: Color(0xFF0000A5),
    errorText: Color(0xFFFF0000),
    bottomButton: Color(0xFF52595D),
    toolButton: Color(0xFF43BFC7),
    talkButton: Color(0xFF1E90FF),
    historyButton: Color(0xFFADD8E6),
    vocabularyButton: Color(0xFF3090C7),
    borderDefault: Color(0xFF98AFC7),
    borderEnable: Color(0xFF2F539B),
    borderFocus: Color(0xFF1F45FC),
  );

  /// Bảng màu dark theme.
  static const AppPalette dark = AppPalette(
    backgroundLight: Color(0xFF0F1D2B),
    backgroundDark: Color(0xFF0B1622),
    backgroundWhite: Color(0xFF152332),
    backgroundGradientStart: Color(0xFF1E5A6E),
    backgroundGradientEnd: Color(0xFF224E84),
    bottomNavBarBackground: Color(0xFF1A2A3A),
    selectedItemBottomNavBar: Color(0xFF2C3F52),
    unselectedItemBottomNavBar: Color(0xFF8FA7BC),
    darkCardBackground: Color(0xFF1B2A3B),
    lightCardBackground: Color(0xFF213549),
    cardPersonal: Color(0xFF1D3044),
    cardItem: Color(0xFF2E4E69),
    cardDailyOnline: Color(0xFF4BA3FF),
    cardDailyOffline: Color(0xFF738395),
    toggleBg: Color(0xFF274159),
    toggleSelected: Color(0xFF45B3D8),
    whiteCard: Color(0xFF1A2B3C),
    greenCard: Color(0xFF56BB69),
    darkGreenCard: Color(0xFF2A8B8B),
    darkBlueCard: Color(0xFF4B97BF),
    label: Color(0xFFDCF3FF),
    labelOnboarding: Color(0xFF9AFB8D),
    primaryText: Color(0xFFE8F1F8),
    lightBlackText: Color(0xFFD1E3F2),
    whiteText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFB8CADB),
    blueDarkText: Color(0xFF77B4FF),
    greenText: Color(0xFF74D68E),
    favourText: Color(0xFFFF6B74),
    vocabDarkText: Color(0xFF90A8FF),
    errorText: Color(0xFFFF7B7B),
    bottomButton: Color(0xFFB5CADB),
    toolButton: Color(0xFF5AC7E0),
    talkButton: Color(0xFF66B7FF),
    historyButton: Color(0xFF345067),
    vocabularyButton: Color(0xFF4B9DD1),
    borderDefault: Color(0xFF47627A),
    borderEnable: Color(0xFF80A6EA),
    borderFocus: Color(0xFF7BA2FF),
  );

  @override
  AppPalette copyWith({
    Color? backgroundLight,
    Color? backgroundDark,
    Color? backgroundWhite,
    Color? backgroundGradientStart,
    Color? backgroundGradientEnd,
    Color? bottomNavBarBackground,
    Color? selectedItemBottomNavBar,
    Color? unselectedItemBottomNavBar,
    Color? darkCardBackground,
    Color? lightCardBackground,
    Color? cardPersonal,
    Color? cardItem,
    Color? cardDailyOnline,
    Color? cardDailyOffline,
    Color? toggleBg,
    Color? toggleSelected,
    Color? whiteCard,
    Color? greenCard,
    Color? darkGreenCard,
    Color? darkBlueCard,
    Color? label,
    Color? labelOnboarding,
    Color? primaryText,
    Color? lightBlackText,
    Color? whiteText,
    Color? secondaryText,
    Color? blueDarkText,
    Color? greenText,
    Color? favourText,
    Color? vocabDarkText,
    Color? errorText,
    Color? bottomButton,
    Color? toolButton,
    Color? talkButton,
    Color? historyButton,
    Color? vocabularyButton,
    Color? borderDefault,
    Color? borderEnable,
    Color? borderFocus,
  }) {
    return AppPalette(
      backgroundLight: backgroundLight ?? this.backgroundLight,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      backgroundWhite: backgroundWhite ?? this.backgroundWhite,
      backgroundGradientStart:
          backgroundGradientStart ?? this.backgroundGradientStart,
      backgroundGradientEnd:
          backgroundGradientEnd ?? this.backgroundGradientEnd,
      bottomNavBarBackground:
          bottomNavBarBackground ?? this.bottomNavBarBackground,
      selectedItemBottomNavBar:
          selectedItemBottomNavBar ?? this.selectedItemBottomNavBar,
      unselectedItemBottomNavBar:
          unselectedItemBottomNavBar ?? this.unselectedItemBottomNavBar,
      darkCardBackground: darkCardBackground ?? this.darkCardBackground,
      lightCardBackground: lightCardBackground ?? this.lightCardBackground,
      cardPersonal: cardPersonal ?? this.cardPersonal,
      cardItem: cardItem ?? this.cardItem,
      cardDailyOnline: cardDailyOnline ?? this.cardDailyOnline,
      cardDailyOffline: cardDailyOffline ?? this.cardDailyOffline,
      toggleBg: toggleBg ?? this.toggleBg,
      toggleSelected: toggleSelected ?? this.toggleSelected,
      whiteCard: whiteCard ?? this.whiteCard,
      greenCard: greenCard ?? this.greenCard,
      darkGreenCard: darkGreenCard ?? this.darkGreenCard,
      darkBlueCard: darkBlueCard ?? this.darkBlueCard,
      label: label ?? this.label,
      labelOnboarding: labelOnboarding ?? this.labelOnboarding,
      primaryText: primaryText ?? this.primaryText,
      lightBlackText: lightBlackText ?? this.lightBlackText,
      whiteText: whiteText ?? this.whiteText,
      secondaryText: secondaryText ?? this.secondaryText,
      blueDarkText: blueDarkText ?? this.blueDarkText,
      greenText: greenText ?? this.greenText,
      favourText: favourText ?? this.favourText,
      vocabDarkText: vocabDarkText ?? this.vocabDarkText,
      errorText: errorText ?? this.errorText,
      bottomButton: bottomButton ?? this.bottomButton,
      toolButton: toolButton ?? this.toolButton,
      talkButton: talkButton ?? this.talkButton,
      historyButton: historyButton ?? this.historyButton,
      vocabularyButton: vocabularyButton ?? this.vocabularyButton,
      borderDefault: borderDefault ?? this.borderDefault,
      borderEnable: borderEnable ?? this.borderEnable,
      borderFocus: borderFocus ?? this.borderFocus,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      backgroundLight: Color.lerp(backgroundLight, other.backgroundLight, t)!,
      backgroundDark: Color.lerp(backgroundDark, other.backgroundDark, t)!,
      backgroundWhite: Color.lerp(backgroundWhite, other.backgroundWhite, t)!,
      backgroundGradientStart:
          Color.lerp(backgroundGradientStart, other.backgroundGradientStart, t)!,
      backgroundGradientEnd:
          Color.lerp(backgroundGradientEnd, other.backgroundGradientEnd, t)!,
      bottomNavBarBackground:
          Color.lerp(bottomNavBarBackground, other.bottomNavBarBackground, t)!,
      selectedItemBottomNavBar: Color.lerp(
        selectedItemBottomNavBar,
        other.selectedItemBottomNavBar,
        t,
      )!,
      unselectedItemBottomNavBar: Color.lerp(
        unselectedItemBottomNavBar,
        other.unselectedItemBottomNavBar,
        t,
      )!,
      darkCardBackground:
          Color.lerp(darkCardBackground, other.darkCardBackground, t)!,
      lightCardBackground:
          Color.lerp(lightCardBackground, other.lightCardBackground, t)!,
      cardPersonal: Color.lerp(cardPersonal, other.cardPersonal, t)!,
      cardItem: Color.lerp(cardItem, other.cardItem, t)!,
      cardDailyOnline: Color.lerp(cardDailyOnline, other.cardDailyOnline, t)!,
      cardDailyOffline:
          Color.lerp(cardDailyOffline, other.cardDailyOffline, t)!,
      toggleBg: Color.lerp(toggleBg, other.toggleBg, t)!,
      toggleSelected: Color.lerp(toggleSelected, other.toggleSelected, t)!,
      whiteCard: Color.lerp(whiteCard, other.whiteCard, t)!,
      greenCard: Color.lerp(greenCard, other.greenCard, t)!,
      darkGreenCard: Color.lerp(darkGreenCard, other.darkGreenCard, t)!,
      darkBlueCard: Color.lerp(darkBlueCard, other.darkBlueCard, t)!,
      label: Color.lerp(label, other.label, t)!,
      labelOnboarding: Color.lerp(labelOnboarding, other.labelOnboarding, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      lightBlackText: Color.lerp(lightBlackText, other.lightBlackText, t)!,
      whiteText: Color.lerp(whiteText, other.whiteText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      blueDarkText: Color.lerp(blueDarkText, other.blueDarkText, t)!,
      greenText: Color.lerp(greenText, other.greenText, t)!,
      favourText: Color.lerp(favourText, other.favourText, t)!,
      vocabDarkText: Color.lerp(vocabDarkText, other.vocabDarkText, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      bottomButton: Color.lerp(bottomButton, other.bottomButton, t)!,
      toolButton: Color.lerp(toolButton, other.toolButton, t)!,
      talkButton: Color.lerp(talkButton, other.talkButton, t)!,
      historyButton: Color.lerp(historyButton, other.historyButton, t)!,
      vocabularyButton:
          Color.lerp(vocabularyButton, other.vocabularyButton, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderEnable: Color.lerp(borderEnable, other.borderEnable, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
