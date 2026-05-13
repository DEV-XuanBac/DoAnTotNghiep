import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/admin/exam_upload_tab.dart';
import 'package:hanziilearnapp/admin/vocabulary_create_tab.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        backgroundColor: context.palette.backgroundLight,
        elevation: 0,
        title: const Text('Quản trị nội dung HSK'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Container(
                height: 50.h,
                decoration: BoxDecoration(
                  color: context.palette.backgroundWhite,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  indicator: BoxDecoration(
                    color: context.palette.blueDarkText,
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  labelColor: context.palette.whiteText,
                  unselectedLabelColor: context.palette.primaryText,
                  labelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Thêm đề thi HSK'),
                    Tab(text: 'Thêm từ vựng HSK'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ExamUploadTab(),
                  VocabularyCreateTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
