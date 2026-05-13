import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/widgets/week_progress.dart';

/// Khối “Cá nhân” (streak, tuần, thời gian online) trên trang chủ.
class HomePersonalSection extends StatelessWidget {
  const HomePersonalSection({
    super.key,
    required this.onlineMins,
    required this.streak,
    required this.checkedDays,
  });

  final int onlineMins;
  final int streak;
  final Set<int> checkedDays;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Cá nhân',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.palette.primaryText,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 8.h),
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: context.palette.cardPersonal,
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50.r),
                    child: Image.asset(
                      'assets/logo/friend_logo.png',
                      width: 70.w,
                      height: 70.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuỗi duy trì đăng nhập',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: context.palette.primaryText,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Đã online được $onlineMins phút',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.palette.secondaryText
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Row(
                    children: [
                      Text(
                        '$streak',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 30.sp,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: WeekProgress(checkedDayIndexes: checkedDays),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
