import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:provider/provider.dart';

class ExampleTab extends StatelessWidget {
  const ExampleTab({super.key, required this.onPlayAudio});

  final Future<void> Function(Word word) onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonProvider>(
      builder: (context, provider, _) {
        final examples = provider.words
            .where((word) => word.exampleHanzi.trim().isNotEmpty)
            .toList();
        if (examples.isEmpty) {
          return Center(
            child: Text(
              'Chưa có ví dụ cho chủ đề này.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          itemCount: examples.length,
          itemBuilder: (_, index) {
            final word = examples[index];
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ví dụ với từ ${word.hanzi}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    word.exampleHanzi,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(word.examplePinyin, style: TextStyle(fontSize: 14.sp)),
                  SizedBox(height: 4.h),
                  Text(
                    word.exampleMeaning,
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => onPlayAudio(
                        Word(
                          id: word.id,
                          hanzi: word.exampleHanzi,
                          pinyin: word.examplePinyin,
                          meaning: word.exampleMeaning,
                          hskLevel: word.hskLevel,
                          topic: word.topic,
                          stt: word.stt,
                        ),
                      ),
                      icon: const Icon(Icons.volume_up_outlined),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
