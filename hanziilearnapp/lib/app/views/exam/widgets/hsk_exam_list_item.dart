import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

class HskExamListItem extends StatelessWidget {
  const HskExamListItem({
    super.key,
    required this.exam,
    required this.onTap,
    this.isCompleted = false,
    this.scoreOutOf10,
    this.attemptCount = 0,
  });

  final HskExam exam;
  final VoidCallback onTap;
  final bool isCompleted;
  final double? scoreOutOf10;
  final int attemptCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: context.palette.backgroundWhite,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.palette.borderDefault.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exam.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.palette.primaryText,
                    ),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: context.palette.greenCard.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(
                        color: context.palette.greenCard.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      scoreOutOf10 == null
                          ? 'Đã hoàn thành'
                          : 'Đã hoàn thành ${scoreOutOf10!.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: context.palette.greenText,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              '${exam.examCode} - ${exam.totalQuestions} câu hỏi',
              style: TextStyle(fontSize: 14.sp, color: context.palette.secondaryText),
            ),
            if (isCompleted && scoreOutOf10 != null) ...[
              SizedBox(height: 4.h),
              Text(
                'Lần làm: ${attemptCount <= 0 ? 1 : attemptCount} - Điểm: ${scoreOutOf10!.toStringAsFixed(1)}/10',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: context.palette.greenText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
