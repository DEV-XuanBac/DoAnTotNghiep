import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/conversation_model.dart';

class ConversationScenarioHeader extends StatelessWidget {
  const ConversationScenarioHeader({super.key, required this.chat});

  final ConversationDialogue chat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${chat.topicChinese} - ${chat.topicVietnamese}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            chat.scenario,
            style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
