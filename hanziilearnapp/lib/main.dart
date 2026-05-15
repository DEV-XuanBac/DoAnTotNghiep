import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/config/app_config.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/datasource/services/vocabulary_reminder_service.dart';
import 'package:hanziilearnapp/app/providers/providers_list.dart';
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:hanziilearnapp/app/widgets/online_session_binder.dart';
import 'package:hanziilearnapp/app/routes/app_pages.dart';
import 'package:hanziilearnapp/app/routes/app_routes.dart';
import 'package:hanziilearnapp/firebase_options.dart';
import 'package:provider/provider.dart';

/// Giữ stack điều hướng khi [MaterialApp] rebuild (đổi theme, v.v.).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await VocabularyReminderService.setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders,
      child: ScreenUtilInit(
        designSize: const Size(360, 800),
        builder: (context, child) {
          final themeMode = context.watch<ThemeProvider>().themeMode;
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: AppConfig.appNm,
            debugShowCheckedModeBanner: false,
            initialRoute: AppRoutes.splash,
            routes: AppPages.routes,
            themeMode: themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            builder: (context, child) {
              return OnlineSessionBinder(
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final palette = AppPalette.light;
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: palette.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.backgroundLight,
      ),
      extensions: const <ThemeExtension<dynamic>>[AppPalette.light],
    );
  }

  ThemeData _buildDarkTheme() {
    final palette = AppPalette.dark;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.blueDarkText,
        brightness: Brightness.dark,
      ),
      extensions: const <ThemeExtension<dynamic>>[AppPalette.dark],
    );
  }
}
