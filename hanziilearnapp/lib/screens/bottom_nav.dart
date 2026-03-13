import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:hanziilearnapp/core/constants.dart';
import 'package:hanziilearnapp/screens/community/community_screen.dart';
import 'package:hanziilearnapp/screens/home_screen.dart';
import 'package:hanziilearnapp/screens/lesson_screen.dart';
import 'package:hanziilearnapp/screens/translate_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late List<Widget> _pages;

  late HomeScreen _homeScreen;
  late TranslateScreen _translateScreen;
  late LessonScreen _lessonScreen;
  late CommunityScreen _communityScreen;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _homeScreen = const HomeScreen();
    _translateScreen = const TranslateScreen();
    _lessonScreen = const LessonScreen();
    _communityScreen = const CommunityScreen();

    _pages = [_homeScreen, _translateScreen, _lessonScreen, _communityScreen];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 60.h,
        backgroundColor: AppColors.backgroundLight,
        color: AppColors.bottomNavBarBackground,
        animationDuration: Duration(milliseconds: 300),
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          Image.asset(
            'assets/iconic/home_ic.png',
            width: 24.w,
            height: 24.h,
            color: AppColors.bottomButton,
          ),
          Image.asset(
            'assets/iconic/translation_ic.png',
            width: 24.w,
            height: 24.h,
            color: AppColors.bottomButton,
          ),
          Image.asset(
            'assets/iconic/book_ic.png',
            width: 24.w,
            height: 24.h,
            color: AppColors.bottomButton,
          ),
          Image.asset(
            'assets/iconic/people_ic.png',
            width: 24.w,
            height: 24.h,
            color: AppColors.bottomButton,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
    );
  }
}
