import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:hanziilearnapp/app/views/community/community_view.dart';
import 'package:hanziilearnapp/app/views/home/home_view.dart';
import 'package:hanziilearnapp/app/views/lesson/lesson_view.dart';
import 'package:hanziilearnapp/app/views/translate/translate_view.dart';
import 'package:provider/provider.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  late int _selectedIndex;
  final GlobalKey<CurvedNavigationBarState> _bottomNavKey =
      GlobalKey<CurvedNavigationBarState>();

  static const _icons = [
    'assets/iconic/home_ic.png',
    'assets/iconic/translation_ic.png',
    'assets/iconic/book_ic.png',
    'assets/iconic/people_ic.png',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _icons.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>().isDarkMode;
    final pages = <Widget>[
      HomeView(
        onRequestTabChange: (index) {
          _goToTab(index, animateBar: true);
        },
      ),
      const TranslateView(),
      const LessonView(),
      const CommunityView(),
    ];

    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavKey,
        height: 60.h,
        backgroundColor: AppColors.backgroundLight,
        color: AppColors.bottomNavBarBackground,
        animationDuration: const Duration(milliseconds: 300),
        index: _selectedIndex,
        onTap: (index) => _goToTab(index),
        items: _icons
            .map(
              (path) => Image.asset(
                path,
                width: 24.w,
                height: 24.h,
                color: AppColors.bottomButton,
              ),
            )
            .toList(),
      ),
      body: pages[_selectedIndex],
    );
  }

  void _goToTab(int index, {bool animateBar = false}) {
    final safeIndex = index.clamp(0, _icons.length - 1);
    if (_selectedIndex != safeIndex) {
      setState(() => _selectedIndex = safeIndex);
    }
    if (animateBar) {
      _bottomNavKey.currentState?.setPage(safeIndex);
    }
  }
}
