import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/datasource/repository/exam_attempt_repository.dart';
import 'package:hanziilearnapp/app/datasource/repository/hsk_exam_repository.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';
import 'package:hanziilearnapp/app/utils/hsk_exam_answer_utils.dart';
import 'package:hanziilearnapp/app/views/exam/hsk_exam_audio_bytes.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_navigation_actions.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_question_card.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_question_image.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_section_content.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_sort_sentences_card.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_sort_word_card.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_states.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_write_sentence_card.dart';
import 'package:provider/provider.dart';

class HskExamTakeView extends StatefulWidget {
  const HskExamTakeView({super.key, required this.examId, required this.level});

  final String examId;
  final String level;

  @override
  State<HskExamTakeView> createState() => _HskExamTakeViewState();
}

class _HskExamTakeViewState extends State<HskExamTakeView> {
  static const double _fixedImageHeight = 160;

  late final IHskExamRepository _examRepo;
  late final IExamAttemptRepository _attemptRepo;
  late final Future<HskExamDetail> _examFuture;
  late final AudioPlayer _audioPlayer;
  final ScrollController _questionScrollController = ScrollController();

  int _currentSectionIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isAudioPlaying = false;
  String? _currentAudioSource;
  Timer? _examTimer;
  Duration? _remainingTime;
  bool _isSubmitting = false;
  bool _didAutoSubmit = false;
  String? _timerExamKey;
  int? _examTimeLimitMinutes;

  @override
  void initState() {
    super.initState();
    _examRepo = context.read<IHskExamRepository>();
    _attemptRepo = context.read<IExamAttemptRepository>();
    _examFuture = _examRepo.getExamDetail(widget.examId);
    _audioPlayer = AudioPlayer();
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _audioDuration = duration);
      }
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _audioPosition = position);
      }
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isAudioPlaying = state == PlayerState.playing);
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = false;
          _audioPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    _questionScrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Làm đề ${widget.level}'),
            if (_examTimeLimitMinutes != null && _examTimeLimitMinutes! > 0)
              Text(
                'Giới hạn: $_examTimeLimitMinutes phút (theo đề)',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: context.palette.secondaryText,
                ),
              ),
          ],
        ),
        backgroundColor: context.palette.backgroundLight,
        elevation: 0,
        actions: [
          if (_remainingTime != null)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _isTimerWarning
                        ? context.palette.errorText.withValues(alpha: 0.08)
                        : context.palette.backgroundWhite,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: _isTimerWarning
                          ? context.palette.errorText.withValues(alpha: 0.8)
                          : context.palette.borderDefault.withValues(
                              alpha: 0.8,
                            ),
                    ),
                  ),
                  child: Text(
                    '$_timerLabel ${_formatDuration(_remainingTime!)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: _isTimerWarning
                          ? context.palette.errorText
                          : context.palette.primaryText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<HskExamDetail>(
        future: _examFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const HskExamLoadingState();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const HskExamErrorState(
              message: 'Không thể tải đề thi. Vui lòng thử lại.',
            );
          }

          final exam = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _ensureExamTimer(exam);
            }
          });
          final sections = exam.sections;
          final questions = exam.allQuestions;
          if (questions.isEmpty || sections.isEmpty) {
            return const HskExamEmptyState(
              message: 'Đề thi chưa có câu hỏi.',
            );
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: _buildExamContent(exam),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<HskExamDetail>(
        future: _examFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              snapshot.hasError ||
              !snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final exam = snapshot.data!;
          if (exam.sections.isEmpty || exam.allQuestions.isEmpty) {
            return const SizedBox.shrink();
          }

          final sections = exam.sections;
          return Container(
            color: context.palette.backgroundLight,
            padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 8.h),
            child: SafeArea(
              child: HskExamNavigationActions(
                canGoPrevious: _currentSectionIndex > 0,
                isLastSection: _currentSectionIndex >= sections.length - 1,
                onPrevious: () => _goToSection(exam, _currentSectionIndex - 1),
                onNextOrSubmit: _currentSectionIndex < sections.length - 1
                    ? () => _goToSection(exam, _currentSectionIndex + 1)
                    : () => _confirmSubmitExam(exam),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExamContent(HskExamDetail exam) {
    final sections = exam.sections;
    final currentSection = sections[_currentSectionIndex];
    final isListeningSection = _isListeningSection(currentSection);
    final sectionAudioPath = _resolveSectionAudioPath(exam, currentSection);
    final currentQuestionImage = currentSection.questionImage?.trim();
    final answeredCount = exam.allQuestions
        .where(
          (q) =>
              HskExamAnswerUtils.hasAnswer(q, _selectedAnswers[q.questionId]),
        )
        .length;
    final progressText =
        'Phần ${_currentSectionIndex + 1}/${sections.length} - Đã làm $answeredCount/${exam.allQuestions.length} câu';

    return HskExamSectionContent(
      exam: exam,
      currentSectionIndex: _currentSectionIndex,
      progressText: progressText,
      questionImagePath: currentQuestionImage,
      imageHeight: _fixedImageHeight,
      onTapQuestionImage: () {
        final p = currentSection.questionImage?.trim();
        if (p != null && p.isNotEmpty) {
          unawaited(showHskExamQuestionImageViewer(context, imagePath: p));
        }
      },
      questionScrollController: _questionScrollController,
      showListeningCard: isListeningSection,
      listeningAudioPath: sectionAudioPath,
      isAudioPlaying: _isAudioPlaying,
      audioDuration: _audioDuration,
      audioPosition: _audioPosition,
      onToggleAudio: _toggleAudio,
      formatDuration: _formatDuration,
      questionWidgets: currentSection.questions
          .map(_buildQuestionWidget)
          .toList(),
    );
  }

  Widget _buildQuestionWidget(HskExamQuestion question) {
    switch (question.questionType) {
      case 'sort_sentences':
        return HskExamSortSentencesCard(
          question: question,
          selectedOrderKey: _selectedAnswers[question.questionId],
          onOrderChanged: (key) {
            setState(() {
              _selectedAnswers[question.questionId] = key;
            });
          },
        );
      case 'sort_word':
        return HskExamSortWordCard(
          question: question,
          selectedSentence: _selectedAnswers[question.questionId],
          onSentenceChanged: (sentence) {
            setState(() {
              _selectedAnswers[question.questionId] = sentence;
            });
          },
        );
      case 'write_sentence':
        return HskExamWriteSentenceCard(
          question: question,
          answerText: _selectedAnswers[question.questionId],
          onAnswerChanged: (text) {
            setState(() {
              _selectedAnswers[question.questionId] = text;
            });
          },
        );
      default:
        return HskExamQuestionCard(
          question: question,
          selectedAnswer: _selectedAnswers[question.questionId],
          onOptionSelected: (option) {
            setState(() {
              _selectedAnswers[question.questionId] = option;
            });
          },
        );
    }
  }

  bool _isListeningSection(HskExamSection section) {
    final skill = section.skill.toLowerCase();
    return skill.contains('listen');
  }

  String? _resolveSectionAudioPath(HskExamDetail exam, HskExamSection section) {
    final fromSection = section.audioAsset?.trim();
    if (fromSection != null && fromSection.isNotEmpty) {
      return fromSection;
    }
    final fromExam = exam.listeningAudioAsset?.trim();
    if (fromExam != null && fromExam.isNotEmpty) {
      return fromExam;
    }
    return 'lib/core/database_HSK_Exam/${exam.level}/${exam.examCode}_listening.mp3';
  }

  Future<void> _toggleAudio(String audioAssetPath) async {
    try {
      final shouldSwitchSource = _currentAudioSource != audioAssetPath;

      if (shouldSwitchSource) {
        _currentAudioSource = audioAssetPath;
        _audioPosition = Duration.zero;
        await _audioPlayer.stop();
        await _playFromAssetPath(audioAssetPath);
        return;
      }

      if (_isAudioPlaying) {
        await _audioPlayer.pause();
        return;
      }
      if (_audioPosition > Duration.zero) {
        await _audioPlayer.resume();
        return;
      }
      await _playFromAssetPath(audioAssetPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không phát được audio: $audioAssetPath\n$error'),
        ),
      );
    }
  }

  Future<void> _playFromAssetPath(String audioAssetPath) async {
    if (audioAssetPath.startsWith('http://') ||
        audioAssetPath.startsWith('https://')) {
      await _audioPlayer.play(UrlSource(audioAssetPath));
      return;
    }

    final data = await loadHskExamAudioBytes(audioAssetPath);
    await _audioPlayer.play(BytesSource(data.buffer.asUint8List()));
  }

  void _goToSection(HskExamDetail exam, int nextIndex) {
    if (nextIndex < 0 || nextIndex >= exam.sections.length) {
      return;
    }

    final nextSection = exam.sections[nextIndex];
    final shouldStopAudio = !_isListeningSection(nextSection);
    if (shouldStopAudio) {
      _audioPlayer.stop();
      _isAudioPlaying = false;
      _audioPosition = Duration.zero;
    }

    setState(() {
      _currentSectionIndex = nextIndex;
      if (shouldStopAudio) {
        _isAudioPlaying = false;
        _audioPosition = Duration.zero;
      }
    });
    _scrollQuestionListToTop();
  }

  void _scrollQuestionListToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_questionScrollController.hasClients) {
        return;
      }
      _questionScrollController.jumpTo(0);
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) {
      return '00:00';
    }
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _timerLabel =>
      _remainingTime != null && _remainingTime!.inSeconds <= 60
      ? 'Sắp hết giờ:'
      : 'Thời gian:';
  bool get _isTimerWarning =>
      _remainingTime != null && _remainingTime!.inSeconds <= 5 * 60;

  void _ensureExamTimer(HskExamDetail exam) {
    if (exam.timeLimitMinutes <= 0 || _didAutoSubmit) {
      return;
    }
    final examKey = '${exam.level}_${exam.examCode}';
    if (_timerExamKey == examKey) {
      return;
    }

    _examTimer?.cancel();
    _timerExamKey = examKey;
    _examTimeLimitMinutes = exam.timeLimitMinutes;
    _remainingTime = Duration(minutes: exam.timeLimitMinutes);

    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _didAutoSubmit) {
        timer.cancel();
        return;
      }

      final current = _remainingTime;
      if (current == null) {
        timer.cancel();
        return;
      }

      if (current.inSeconds <= 1) {
        setState(() => _remainingTime = Duration.zero);
        timer.cancel();
        _handleTimeUp(exam);
        return;
      }

      setState(() => _remainingTime = current - const Duration(seconds: 1));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleTimeUp(HskExamDetail exam) {
    if (_didAutoSubmit) {
      return;
    }
    _didAutoSubmit = true;
    _submitExam(exam, forcedByTimer: true);
  }

  Future<void> _confirmSubmitExam(HskExamDetail exam) async {
    if (_isSubmitting) {
      return;
    }
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận nộp bài'),
          content: const Text(
            'Bạn có chắc muốn nộp bài ngay bây giờ không?\n'
            'Sau khi nộp, hệ thống sẽ chấm điểm và hiển thị câu sai + đáp án đúng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Chưa nộp'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Nộp bài'),
            ),
          ],
        );
      },
    );
    if (!mounted || shouldSubmit != true) {
      return;
    }
    await _submitExam(exam);
  }

  Future<void> _submitExam(
    HskExamDetail exam, {
    bool forcedByTimer = false,
  }) async {
    if (_isSubmitting) {
      return;
    }
    _isSubmitting = true;
    _examTimer?.cancel();

    final questions = exam.allQuestions;
    if (questions.isEmpty) {
      _isSubmitting = false;
      return;
    }

    var correctCount = 0;
    final wrongLines = <String>[];
    for (final question in questions) {
      final selected = _selectedAnswers[question.questionId];
      if (HskExamAnswerUtils.isAnswerCorrect(question, selected)) {
        correctCount++;
      } else {
        final selectedLabel = !HskExamAnswerUtils.hasAnswer(question, selected)
            ? 'Chưa làm'
            : selected!;
        wrongLines.add(
          'Câu ${question.questionId}: Bạn chọn $selectedLabel - Đúng: ${question.correctAnswer}',
        );
      }
    }

    final unanswered = questions
        .where(
          (q) =>
              !HskExamAnswerUtils.hasAnswer(q, _selectedAnswers[q.questionId]),
        )
        .length;
    final scoreOn10 = questions.isEmpty
        ? 0.0
        : ((correctCount / questions.length) * 10).clamp(0, 10).toDouble();
    final attemptNumber = await _peekNextAttemptNumber();
    if (!mounted) {
      _isSubmitting = false;
      return;
    }

    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Kết quả bài thi'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lần làm thứ $attemptNumber\n'
                    'Điểm: ${scoreOn10.toStringAsFixed(1)}/10\n'
                    'Đúng: $correctCount/${questions.length}\n'
                    'Sai: ${questions.length - correctCount} câu\n'
                    'Chưa làm: $unanswered câu',
                  ),
                  if (forcedByTimer) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Đã hết thời gian, hệ thống tự động nộp bài.',
                    ),
                  ],
                  if (wrongLines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Các câu sai và đáp án đúng:',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    ...wrongLines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(line),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!forcedByTimer)
                TextButton(
                  onPressed: () {
                    _isSubmitting = false;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Xem lại bài'),
                ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _recordExamCompletion(
                    exam: exam,
                    correctCount: correctCount,
                    totalQuestions: questions.length,
                  );
                  _isSubmitting = false;
                  if (!mounted) {
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Hoàn thành'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _recordExamCompletion({
    required HskExamDetail exam,
    required int correctCount,
    required int totalQuestions,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final scoreOn10 = totalQuestions <= 0
        ? 0.0
        : ((correctCount / totalQuestions) * 10).clamp(0, 10).toDouble();

    await _attemptRepo.saveExamCompletion(
      userId: user.uid,
      examId: widget.examId,
      examCode: exam.examCode,
      level: exam.level,
      correctCount: correctCount,
      totalQuestions: totalQuestions,
      scoreOn10: scoreOn10,
    );
  }

  Future<int> _peekNextAttemptNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 1;
    }
    return _attemptRepo.peekNextAttemptNumber(
      userId: user.uid,
      examId: widget.examId,
    );
  }
}
