import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:hanziilearnapp/app/views/home/widgets/word_tile.dart';

/// Kết quả tra cứu + giải thích ngữ cảnh + từ liên quan (tách khỏi màn HomeView).
class HomeResultPanel extends StatelessWidget {
  const HomeResultPanel({
    super.key,
    required this.pickedWord,
    required this.relatedWords,
    required this.usageWordId,
    required this.usageExplain,
    required this.usageLoading,
    required this.onSpeakPicked,
    required this.onSpeakRelated,
  });

  final Word pickedWord;
  final List<Word> relatedWords;
  final String usageWordId;
  final String usageExplain;
  final bool usageLoading;
  final VoidCallback onSpeakPicked;
  final void Function(Word word) onSpeakRelated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.palette.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.palette.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết quả từ vựng',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: context.palette.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          WordTile(word: pickedWord, onSpeak: onSpeakPicked),
          if (usageWordId == pickedWord.id &&
              (usageLoading || usageExplain.isNotEmpty)) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: context.palette.lightCardBackground.withValues(
                  alpha: 0.65,
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: usageLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Đang tải...',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: context.palette.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      usageExplain,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.45,
                        color: context.palette.primaryText,
                      ),
                    ),
            ),
          ],
          if (relatedWords.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              'Từ liên quan',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: context.palette.primaryText,
              ),
            ),
            SizedBox(height: 4.h),
            ...relatedWords.take(8).map((word) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: WordTile(
                  word: word,
                  onSpeak: () => onSpeakRelated(word),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
