import 'dart:async';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/datasource/services/vocabulary_reminder_service.dart';
import 'package:hanziilearnapp/app/views/community/community_view.dart';
import 'package:hanziilearnapp/app/views/home/home_view.dart';
import 'package:hanziilearnapp/app/views/lesson/lesson_view.dart';
import 'package:hanziilearnapp/app/views/translate/translate_view.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(VocabularyReminderService.syncScheduleWithPrefs());
    });
  }

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: CurvedNavigationBar(
          key: _bottomNavKey,
          height: 50.h,
          backgroundColor: context.palette.backgroundLight,
          color: context.palette.bottomNavBarBackground,
          animationDuration: const Duration(milliseconds: 300),
          index: _selectedIndex,
          onTap: _goToTab,
          items: _icons
              .map(
                (path) => Image.asset(
                  path,
                  width: 24.w,
                  height: 24.h,
                  color: context.palette.bottomButton,
                ),
              )
              .toList(),
        ),
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
