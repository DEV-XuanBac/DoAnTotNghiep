import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:hanziilearnapp/app/views/exam/hsk_exam_list_view.dart';
import 'package:hanziilearnapp/app/views/hsk_vocab/hsk_vocab_view.dart';
import 'package:provider/provider.dart';

class LessonView extends StatefulWidget {
  const LessonView({super.key});

  @override
  State<LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends State<LessonView> {
  static const List<String> _hskLevels = [
    'HSK1',
    'HSK2',
    'HSK3',
    'HSK4',
    'HSK5',
    'HSK6',
  ];
  late final Future<void> _initialLoadFuture;

  @override
  void initState() {
    super.initState();
    final completer = Completer<void>();
    _initialLoadFuture = completer.future;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<LessonProvider>().loadHskLevelCounts(_hskLevels);
      } finally {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialLoadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  Text(
                    'Góc luyện tập',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  SizedBox(height: 16.h),
                  _buildNotebookCard(),
                  SizedBox(height: 18.h),
                  Text(
                    'Học từ vựng',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildHorizontalHskSection(),

                  SizedBox(height: 18.h),
                  Text(
                    'Luyện thi HSK',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildHorizontalExamSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalHskSection() {
    final columns = _buildColumns(_hskLevels);
    final itemHeight = 90.h;
    final rowSpacing = 12.h;

    return SizedBox(
      height: (itemHeight * 2) + rowSpacing,
      child: Consumer<LessonProvider>(
        builder: (context, provider, _) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: columns.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (_, index) {
              final levelColumn = columns[index];
              return Column(
                children: [
                  _buildHskCard(levelColumn[0], provider, itemHeight),
                  SizedBox(height: rowSpacing),
                  if (levelColumn.length > 1)
                    _buildHskCard(levelColumn[1], provider, itemHeight)
                  else
                    SizedBox(height: itemHeight),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHorizontalExamSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12.w) / 2;

        return Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: _hskLevels
              .map((level) => _buildExamCard(level, cardWidth))
              .toList(),
        );
      },
    );
  }

  Widget _buildHskCard(
    String level,
    LessonProvider provider,
    double itemHeight,
  ) {
    final count = provider.levelWordCounts[level];
    final countLabel = count == null ? 'Đang tải...' : '$count từ vựng';

    return _HskLevelCard(
      level: level,
      countLabel: countLabel,
      height: itemHeight,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HskVocabView(hskLevel: level)),
        );
      },
    );
  }

  Widget _buildExamCard(String level, double width) {
    return _ExamLevelCard(
      level: level,
      countLabel: '10 đề thi',
      width: width,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HskExamListView(hskLevel: level)),
        );
      },
    );
  }

  List<List<String>> _buildColumns(List<String> levels) {
    final result = <List<String>>[];
    for (var i = 0; i < levels.length; i += 2) {
      final next = i + 2;
      result.add(
        levels.sublist(i, next > levels.length ? levels.length : next),
      );
    }
    return result;
  }

  Widget _buildNotebookCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Handle tap event
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.talkButton,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.borderFocus.withValues(alpha: 0.4),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  child: Center(
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/logo/take_note_ic.png',
                          width: 56.w,
                          height: 56.w,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Sổ tay học tập',
                          style: TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CounterTag(
                    color: AppColors.greenCard,
                    text: '5',
                    label: 'đã học',
                  ),
                  SizedBox(height: 12.h),
                  _CounterTag(
                    color: AppColors.darkBlueCard,
                    text: '3',
                    label: 'yêu thích',
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.bottomButton,
                  AppColors.bottomButton.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '+0 từ mới hôm nay',
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterTag extends StatelessWidget {
  const _CounterTag({
    required this.color,
    required this.text,
    required this.label,
  });

  final Color color;
  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: AppColors.whiteText,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HskLevelCard extends StatelessWidget {
  const _HskLevelCard({
    required this.level,
    required this.countLabel,
    required this.height,
    required this.onTap,
  });

  final String level;
  final String countLabel;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Ink(
        width: 118.w,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.borderDefault.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              level,
              style: TextStyle(
                color: AppColors.vocabDarkText,
                fontWeight: FontWeight.bold,
                fontSize: 17.sp,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              countLabel,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamLevelCard extends StatelessWidget {
  const _ExamLevelCard({
    required this.level,
    required this.countLabel,
    required this.width,
    required this.onTap,
  });

  final String level;
  final String countLabel;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Ink(
        width: width,
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.borderDefault.withValues(alpha: 0.8),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đề thi $level',
              style: TextStyle(
                color: AppColors.vocabDarkText,
                fontWeight: FontWeight.bold,
                fontSize: 17.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              countLabel,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
