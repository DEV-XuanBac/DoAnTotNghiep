import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class TranslateResultCard extends StatelessWidget {
  const TranslateResultCard({
    super.key,
    required this.isLoading,
    required this.translatedText,
    required this.pinyinText,
  });

  final bool isLoading;
  final String translatedText;
  final String pinyinText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderEnable, width: 1.w),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (translatedText.isEmpty) {
      return Text(
        'Bản dịch',
        style: TextStyle(
          color: AppColors.secondaryText,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pinyinText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(pinyinText, style: TextStyle(fontSize: 14.sp)),
          ),
        SelectableText(
          translatedText,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
