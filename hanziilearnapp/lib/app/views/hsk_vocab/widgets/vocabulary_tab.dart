import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:hanziilearnapp/app/views/hsk_vocab/widgets/word_card.dart';
import 'package:provider/provider.dart';

class VocabularyTab extends StatelessWidget {
  const VocabularyTab({
    super.key,
    required this.hskLevel,
    required this.onPlayAudio,
    required this.onSaveWord,
  });

  final String hskLevel;
  final Future<void> Function(Word word) onPlayAudio;
  final Future<void> Function(Word word) onSaveWord;

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonProvider>(
      builder: (context, provider, _) {
        if (provider.loading && provider.words.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.words.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tai du lieu that bai',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.errorText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  ElevatedButton(
                    onPressed: () => provider.loadWordsByTopic(
                      level: hskLevel,
                      topic: provider.currentTopic,
                    ),
                    child: const Text('Thu lai'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.words.isEmpty) {
          return Center(
            child: Text(
              'Chua co du lieu cho $hskLevel',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadWordsByTopic(
            level: hskLevel,
            topic: provider.currentTopic,
          ),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            itemCount: provider.words.length,
            itemBuilder: (context, index) {
              final word = provider.words[index];
              return WordCard(
                word: word,
                onPlayAudio: onPlayAudio,
                onSaveWord: onSaveWord,
              );
            },
          ),
        );
      },
    );
  }
}
