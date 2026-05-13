import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';

class WeekProgress extends StatelessWidget {
  const WeekProgress({
    super.key,
    this.checkedDayIndexes = const <int>{},
    this.currentDayIndex,
  });

  final Set<int> checkedDayIndexes;
  final int? currentDayIndex;

  @override
  Widget build(BuildContext context) {
    final days = <String>['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final todayIndex = currentDayIndex ?? DateTime.now().weekday - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(days.length, (index) {
        final isChecked = checkedDayIndexes.contains(index);
        final isToday = index == todayIndex;
        return Column(
          children: [
            Container(
              width: 34.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: isChecked
                    ? context.palette.cardDailyOnline
                    : context.palette.cardDailyOffline.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(
                        color: context.palette.primaryText.withValues(alpha: 0.35),
                        width: 1.5,
                      )
                    : null,
              ),
              child: isChecked
                  ? Icon(Icons.check, color: context.palette.whiteText, size: 20.sp)
                  : null,
            ),
            SizedBox(height: 4.h),
            Text(
              days[index],
              style: TextStyle(
                color: isChecked
                    ? context.palette.cardDailyOnline
                    : context.palette.cardDailyOffline.withValues(alpha: 0.8),
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
