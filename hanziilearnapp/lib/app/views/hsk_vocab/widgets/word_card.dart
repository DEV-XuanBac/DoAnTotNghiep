import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:provider/provider.dart';

class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.onPlayAudio,
    required this.onSaveWord,
  });

  final Word word;
  final Future<void> Function(Word word) onPlayAudio;
  final Future<void> Function(Word word) onSaveWord;

  @override
  Widget build(BuildContext context) {
    final bookmarked = context.select<LessonProvider, bool>(
      (value) => value.isBookmarked(word.id),
    );

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(26.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: word.hanzi,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 22.sp,
                        ),
                      ),
                      TextSpan(
                        text: ' [${word.pinyin}]',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                          fontSize: 17.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onPlayAudio(word),
                icon: const Icon(Icons.volume_up_outlined),
              ),
              IconButton(
                onPressed: () => onSaveWord(word),
                icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            word.meaning,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      
    );
  }
}
