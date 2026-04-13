import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/datasource/network_services/hsk_exam_service.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';
import 'package:hanziilearnapp/app/views/exam/hsk_exam_take_view.dart';

class HskExamListView extends StatefulWidget {
  const HskExamListView({super.key, required this.hskLevel});

  final String hskLevel;

  @override
  State<HskExamListView> createState() => _HskExamListViewState();
}

class _HskExamListViewState extends State<HskExamListView> {
  late final Future<List<HskExam>> _examFuture;
  final HskExamService _examService = HskExamService();

  @override
  void initState() {
    super.initState();
    _examFuture = _examService.getExamsByLevel(widget.hskLevel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Danh sách đề thi ${widget.hskLevel}'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: FutureBuilder<List<HskExam>>(
        future: _examFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Không thể tải danh sách đề thi. Vui lòng thử lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            );
          }

          final exams = snapshot.data ?? [];
          if (exams.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Hiện đề thi cấp độ ${widget.hskLevel} chưa được cập nhật',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(14.w),
            itemCount: exams.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final exam = exams[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HskExamTakeView(
                        examAssetPath: exam.assetPath,
                        level: widget.hskLevel,
                      ),
                    ),
                  );
                },
                child: Ink(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.borderDefault.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '${exam.examCode} - ${exam.totalQuestions} câu hỏi',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
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
