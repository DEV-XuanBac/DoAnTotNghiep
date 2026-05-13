import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
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
        color: context.palette.lightCardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      word.hanzi,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: context.palette.primaryText,
                      ),
                    ),
                    Text(
                      '/${word.pinyin}/',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSpeak,
                tooltip: 'Phát âm từ vựng',
                icon: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: context.palette.secondaryText,
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
            style: TextStyle(
              fontSize: 14.sp,
              color: context.palette.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
