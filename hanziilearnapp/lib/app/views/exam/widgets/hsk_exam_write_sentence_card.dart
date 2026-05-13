import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

class HskExamWriteSentenceCard extends StatefulWidget {
  const HskExamWriteSentenceCard({
    super.key,
    required this.question,
    required this.answerText,
    required this.onAnswerChanged,
  });

  final HskExamQuestion question;
  final String? answerText;
  final ValueChanged<String> onAnswerChanged;

  @override
  State<HskExamWriteSentenceCard> createState() => _HskExamWriteSentenceCardState();
}

class _HskExamWriteSentenceCardState extends State<HskExamWriteSentenceCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.answerText ?? '');
  }

  @override
  void didUpdateWidget(covariant HskExamWriteSentenceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId) {
      _controller.text = widget.answerText ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
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
              'Câu ${q.questionId} (${q.code}) — Đặt câu',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.palette.primaryText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Dùng từ gợi ý sau để viết một câu hoàn chỉnh:',
              style: TextStyle(fontSize: 12.sp, color: context.palette.secondaryText),
            ),
            SizedBox(height: 6.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: context.palette.lightCardBackground,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: context.palette.borderDefault.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                q.questionText,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: context.palette.bottomButton,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              onChanged: widget.onAnswerChanged,
              style: TextStyle(fontSize: 14.sp, color: context.palette.primaryText),
              decoration: InputDecoration(
                hintText: 'Nhập câu của bạn…',
                filled: true,
                fillColor: context.palette.backgroundWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.all(12.w),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
