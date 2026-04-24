import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:hanziilearnapp/app/views/hsk_vocab/widgets/example_tab.dart';
import 'package:hanziilearnapp/app/views/hsk_vocab/widgets/review_tab.dart';
import 'package:hanziilearnapp/app/views/hsk_vocab/widgets/topic_selection_tab.dart';
import 'package:hanziilearnapp/app/views/hsk_vocab/widgets/vocabulary_tab.dart';
import 'package:provider/provider.dart';

class HskVocabView extends StatefulWidget {
  const HskVocabView({super.key, required this.hskLevel});

  final String hskLevel;

  @override
  State<HskVocabView> createState() => _HskVocabViewState();
}

class _HskVocabViewState extends State<HskVocabView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadTopicsByHskLevel(widget.hskLevel);
    });
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _playWordAudio(Word word) async {
    try {
      if (word.ttsUrl.trim().isNotEmpty) {
        await _audioPlayer.play(UrlSource(word.ttsUrl.trim()));
      } else {
        await _tts.speak(word.hanzi);
      }
    } catch (_) {
      await _tts.speak(word.hanzi);
    }
  }

  Future<void> _onChooseTopic(String topic) async {
    final provider = context.read<LessonProvider>();
    await provider.loadWordsByTopic(level: widget.hskLevel, topic: topic);
  }

  Future<void> _toggleSaveWord(Word word) async {
    final provider = context.read<LessonProvider>();
    try {
      await provider.toggleBookmark(word);
      if (!mounted) {
        return;
      }
      final saved = provider.isBookmarked(word.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? 'Đã lưu vào sổ tay' : 'Đã bỏ lưu từ này.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Consumer<LessonProvider>(
            builder: (context, provider, _) {
              final title = provider.currentTopic.isEmpty
                  ? widget.hskLevel
                  : '${widget.hskLevel} - ${provider.currentTopic}';
              return Text(title);
            },
          ),
          centerTitle: true,
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
        ),
        body: Consumer<LessonProvider>(
          builder: (context, provider, _) {
            if (provider.currentTopic.isEmpty) {
              return TopicSelectionTab(
                hskLevel: widget.hskLevel,
                onTapTopic: _onChooseTopic,
              );
            }

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  child: Container(
                    height: 52.h,
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: AppColors.blueDarkText,
                        borderRadius: BorderRadius.circular(26.r),
                      ),
                      labelColor: AppColors.whiteText,
                      unselectedLabelColor: AppColors.primaryText,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Từ vựng'),
                        Tab(text: 'Ví dụ'),
                        Tab(text: 'Ôn tập'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: TabBarView(
                    children: [
                      VocabularyTab(
                        hskLevel: widget.hskLevel,
                        onPlayAudio: _playWordAudio,
                        onSaveWord: _toggleSaveWord,
                      ),
                      ExampleTab(onPlayAudio: _playWordAudio),
                      ReviewTab(
                        words: provider.words,
                        hskLevel: widget.hskLevel,
                        topic: provider.currentTopic,
                        isCompleted: provider.reviewCompleted,
                        savedResult: provider.reviewResult,
                        onComplete:
                            ({
                              required int totalQuestions,
                              required int correctAnswers,
                              required List<Map<String, dynamic>> wrongItems,
                              required List<Map<String, dynamic>> reviewedWords,
                            }) => provider.saveReviewResult(
                              level: widget.hskLevel,
                              topic: provider.currentTopic,
                              totalQuestions: totalQuestions,
                              correctAnswers: correctAnswers,
                              wrongItems: wrongItems,
                              reviewedWords: reviewedWords,
                            ),
                        onPlayAudio: _playWordAudio,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
