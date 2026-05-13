import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:hanziilearnapp/app/views/home/widgets/word_tile.dart';

/// Gợi ý từ khi người dùng gõ ô tìm kiếm (tách khỏi màn HomeView).
class HomeSuggestionPanel extends StatelessWidget {
  const HomeSuggestionPanel({
    super.key,
    required this.searching,
    required this.searchSubmitted,
    required this.searchQuery,
    required this.suggestions,
    required this.onPickWord,
    required this.onSpeakWord,
  });

  final bool searching;
  final bool searchSubmitted;
  final String searchQuery;
  final List<Word> suggestions;
  final void Function(Word word) onPickWord;
  final void Function(Word word) onSpeakWord;

  @override
  Widget build(BuildContext context) {
    if (searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (searchSubmitted) {
      return const SizedBox.shrink();
    }
    if (searchQuery.trim().isEmpty || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Gợi ý từ vựng',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: context.palette.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          ...suggestions.take(6).map((word) {
            return InkWell(
              onTap: () => onPickWord(word),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: WordTile(word: word, onSpeak: () => onSpeakWord(word)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
