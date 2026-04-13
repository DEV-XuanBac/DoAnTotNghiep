import 'package:flutter/material.dart';
import 'package:hanziilearnapp/app/routes/app_routes.dart';
import 'package:hanziilearnapp/app/views/onboarding/onboarding_view.dart';
import 'package:hanziilearnapp/app/views/shell/bottom_nav.dart';

abstract class AppPages {
  AppPages._();

  static Map<String, Widget Function(dynamic)> routes = {
    AppRoutes.splash: (context) => const OnboardingView(),
    AppRoutes.main: (context) => const BottomNav(),
  };
}
