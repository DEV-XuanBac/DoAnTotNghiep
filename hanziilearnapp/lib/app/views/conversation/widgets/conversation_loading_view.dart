import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/core/constants/conversation_constants.dart';

class ConversationLoadingView extends StatelessWidget {
  const ConversationLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            ConversationConstants.loadingDlg,
            style: TextStyle(fontSize: 16.sp, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
