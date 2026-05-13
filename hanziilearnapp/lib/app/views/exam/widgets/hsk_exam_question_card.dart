import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

class HskExamQuestionCard extends StatelessWidget {
  const HskExamQuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onOptionSelected,
  });

  final HskExamQuestion question;
  final String? selectedAnswer;
  final ValueChanged<String> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: context.palette.backgroundWhite,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: context.palette.borderDefault.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu ${question.questionId} (${question.code})',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.palette.primaryText,
              ),
            ),
            if (question.questionText.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                question.questionText,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.palette.secondaryText,
                ),
              ),
            ],
            SizedBox(height: 8.h),
            ...question.options.map((option) {
              final isSelected = selectedAnswer == option;
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: () => onOptionSelected(option),
                  child: Ink(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.palette.lightCardBackground
                          : context.palette.backgroundWhite,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected
                            ? context.palette.bottomButton
                            : context.palette.borderDefault.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 17.sp,
                          color: isSelected
                              ? context.palette.bottomButton
                              : context.palette.secondaryText,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: context.palette.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
