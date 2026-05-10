import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

class WordTile extends StatelessWidget {
  const WordTile({super.key, required this.word, this.onSpeak});

  final Word word;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                word.hanzi,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(width: 24.w),
              Text(
                "/${word.pinyin}/",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: onSpeak,
                tooltip: 'Phát âm từ vựng',
                icon: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.secondaryText,
                    size: 22.sp,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),

          SizedBox(height: 2.h),
          Text(
            word.meaning,
            style: TextStyle(fontSize: 14.sp, color: AppColors.primaryText),
          ),
        ],
      ),
    );
  }
}
