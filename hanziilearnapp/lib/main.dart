import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/config/app_config.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/providers/providers_list.dart';
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:hanziilearnapp/app/routes/app_pages.dart';
import 'package:hanziilearnapp/app/routes/app_routes.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp(
                title: AppConfig.appName,
                debugShowCheckedModeBanner: false,
                initialRoute: AppRoutes.splash,
                routes: AppPages.routes,
                themeMode: themeProvider.themeMode,
                theme: ThemeData(
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: const Color(0xFFE0FFFF),
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFFE0FFFF),
                    brightness: Brightness.light,
                  ),
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: const Color(0xFF0F1D2B),
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: AppColors.blueDarkText,
                    brightness: Brightness.dark,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
