import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/community_announcement_model.dart';

class CommunityAnnouncementBanner extends StatelessWidget {
  const CommunityAnnouncementBanner({super.key, required this.announcement});

  final CommunityAnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.palette.lightCardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.palette.blueDarkText.withValues(alpha: 0.35),
          width: 1.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 20.sp,
            color: context.palette.blueDarkText,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN thông báo',
                  style: TextStyle(
                    color: context.palette.blueDarkText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  announcement.content,
                  style: TextStyle(
                    color: context.palette.primaryText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
