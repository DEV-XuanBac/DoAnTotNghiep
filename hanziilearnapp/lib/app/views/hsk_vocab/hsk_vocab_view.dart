import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:hanziilearnapp/app/providers/notebook_provider.dart';
import 'package:hanziilearnapp/app/providers/review_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final lesson = context.read<LessonProvider>();
      final review = context.read<ReviewProvider>();
      await Future.wait<void>([
        lesson.loadTopicsByHskLevel(widget.hskLevel),
        review.loadTopicCompletionByLevel(widget.hskLevel),
      ]);
    });
    unawaited(_initTts());
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    unawaited(_tts.stop());
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
    final lesson = context.read<LessonProvider>();
    final notebook = context.read<NotebookProvider>();
    final review = context.read<ReviewProvider>();
    await lesson.loadWordsByTopic(level: widget.hskLevel, topic: topic);
    if (!mounted) {
      return;
    }
    await Future.wait<void>([
      notebook.syncBookmarksForWords(lesson.words),
      review.loadReviewResult(level: widget.hskLevel, topic: topic),
    ]);
  }

  Future<void> _toggleSaveWord(Word word) async {
    final notebook = context.read<NotebookProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await notebook.toggleBookmark(word);
      if (!mounted) {
        return;
      }
      final saved = notebook.isBookmarked(word.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(saved ? 'Đã lưu vào sổ tay' : 'Đã bỏ lưu từ này.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _returnToTopicSelection() {
    context.read<LessonProvider>().returnToTopicSelection();
    context.read<ReviewProvider>().clearCurrent();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.palette.backgroundLight,
        appBar: AppBar(
          leading: Consumer<LessonProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (provider.currentTopic.isNotEmpty) {
                    _returnToTopicSelection();
                    return;
                  }
                  Navigator.of(context).maybePop();
                },
              );
            },
          ),
          title: Consumer<LessonProvider>(
            builder: (context, provider, _) {
              final title = provider.currentTopic.isEmpty
                  ? widget.hskLevel
                  : '${widget.hskLevel} - ${provider.currentTopic}';
              return Text(title);
            },
          ),
          centerTitle: true,
          backgroundColor: context.palette.backgroundLight,
          elevation: 0,
        ),
        body: Consumer2<LessonProvider, ReviewProvider>(
          builder: (context, provider, review, _) {
            return PopScope(
              canPop: provider.currentTopic.isEmpty,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) {
                  return;
                }
                if (provider.currentTopic.isNotEmpty) {
                  _returnToTopicSelection();
                }
              },
              child: provider.currentTopic.isEmpty
                  ? TopicSelectionTab(
                      hskLevel: widget.hskLevel,
                      onTapTopic: _onChooseTopic,
                    )
                  : Column(
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
                              color: context.palette.backgroundWhite,
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: TabBar(
                              indicator: BoxDecoration(
                                color: context.palette.blueDarkText,
                                borderRadius: BorderRadius.circular(26.r),
                              ),
                              labelColor: context.palette.whiteText,
                              unselectedLabelColor: context.palette.primaryText,
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
                                isCompleted: review.reviewCompleted,
                                savedResult: review.reviewResult,
                                onComplete:
                                    ({
                                      required int totalQuestions,
                                      required int correctAnswers,
                                      required List<Map<String, dynamic>>
                                          wrongItems,
                                      required List<Map<String, dynamic>>
                                          reviewedWords,
                                    }) => review.saveReviewResult(
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
                    ),
            );
          },
        ),
      ),
    );
  }
}
