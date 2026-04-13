import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/views/community/community_view.dart';
import 'package:hanziilearnapp/app/views/home/home_view.dart';
import 'package:hanziilearnapp/app/views/lesson/lesson_view.dart';
import 'package:hanziilearnapp/app/views/translate/translate_view.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    HomeView(),
    TranslateView(),
    LessonView(),
    CommunityView(),
  ];

  static const _icons = [
    'assets/iconic/home_ic.png',
    'assets/iconic/translation_ic.png',
    'assets/iconic/book_ic.png',
    'assets/iconic/people_ic.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 60.h,
        backgroundColor: AppColors.backgroundLight,
        color: AppColors.bottomNavBarBackground,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _icons
            .map((path) => Image.asset(
                  path,
                  width: 24.w,
                  height: 24.h,
                  color: AppColors.bottomButton,
                ))
            .toList(),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
