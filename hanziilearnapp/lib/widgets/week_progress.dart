import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/core/constants.dart';

class WeekProgress extends StatelessWidget {
  const WeekProgress({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
    int currentDayIndex =
        DateTime.now().weekday - 1; // Lấy index của ngày hiện tại (0-6)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(days.length, (index) {
        bool isToday =
            index ==
            currentDayIndex; // Kiểm tra xem ngày hiện tại có trùng với ngày đang xét không
        return Column(
          children: [
            Container(
              width: 34.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.cardDailyOnline
                    : AppColors.cardDailyOffline.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: isToday
                  ? Icon(Icons.check, color: AppColors.whiteText, size: 20.sp)
                  : null,
            ),
            SizedBox(height: 4.h),
            Text(
              days[index],
              style: TextStyle(
                color: isToday
                    ? AppColors.cardDailyOnline
                    : AppColors.cardDailyOffline.withOpacity(0.8),
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }),
    );
  }
}
