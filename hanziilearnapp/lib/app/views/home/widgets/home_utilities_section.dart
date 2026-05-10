import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class HomeUtilitiesSection extends StatelessWidget {
  const HomeUtilitiesSection({
    super.key,
    required this.onConversation,
    required this.onHistory,
    required this.onVocabulary,
  });

  final VoidCallback onConversation;
  final VoidCallback onHistory;
  final VoidCallback onVocabulary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Tiện ích',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: onConversation,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.talkButton.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/logo/panda_talking_ic.png',
                      width: 70.w,
                      height: 70.h,
                    ),
                    Text(
                      'Luyện nói',
                      style: TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: onHistory,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.historyButton,
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Lịch sử',
                          style: TextStyle(
                            color: AppColors.blueDarkText,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 20.w),
                        Image.asset(
                          'assets/iconic/history_search_ic.png',
                          width: 36.w,
                          height: 36.h,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: onVocabulary,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 17.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.vocabularyButton,
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Từ vựng',
                          style: TextStyle(
                            color: AppColors.vocabDarkText,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Image.asset(
                          'assets/logo/dict_hsk_ic.png',
                          width: 36.w,
                          height: 36.h,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
      ],
    );
  }
}
