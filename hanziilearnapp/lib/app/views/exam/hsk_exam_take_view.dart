import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/datasource/network_services/hsk_exam_service.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_listening_audio_card.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_navigation_actions.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_question_card.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_states.dart';

class HskExamTakeView extends StatefulWidget {
  const HskExamTakeView({super.key, required this.examId, required this.level});

  final String examId;
  final String level;

  @override
  State<HskExamTakeView> createState() => _HskExamTakeViewState();
}

class _HskExamTakeViewState extends State<HskExamTakeView> {
  static const double _fixedImageHeight = 160;

  final HskExamService _examService = HskExamService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  @override
  void initState() {
    super.initState();
    _examFuture = _examService.getExamDtl(widget.examId);
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Làm đề ${widget.level}'),
        backgroundColor: AppColors.backgroundLight,
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
                        ? AppColors.errorText.withValues(alpha: 0.08)
                        : AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: _isTimerWarning
                          ? AppColors.errorText.withValues(alpha: 0.8)
                          : AppColors.borderDefault.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Text(
                    '$_timerLabel ${_formatDuration(_remainingTime!)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: _isTimerWarning
                          ? AppColors.errorText
                          : AppColors.primaryText,
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
          _ensureExamTimer(exam);
          final sections = exam.sections;
          final questions = exam.allQuestions;
          if (questions.isEmpty || sections.isEmpty) {
            return const HskExamEmptyState(message: 'Đề thi chưa có câu hỏi.');
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
            color: AppColors.backgroundLight,
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
    final progressText =
        'Phần ${_currentSectionIndex + 1}/${sections.length} - Đã làm ${_selectedAnswers.length}/${exam.allQuestions.length} câu';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          color: AppColors.backgroundWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam.title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                progressText,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                currentSection.sectionTitle,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 10.h),
              if (currentQuestionImage != null &&
                  currentQuestionImage.isNotEmpty) ...[
                _buildQuestionImage(
                  currentQuestionImage,
                  imageHeight: _fixedImageHeight,
                  onTap: () => _showQuestionImageViewer(currentQuestionImage),
                ),
                SizedBox(height: 10.h),
              ],
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.borderDefault.withValues(alpha: 0.7),
              ),
            ),
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (notification) {
                notification.disallowIndicator();
                return true;
              },
              child: ListView(
                controller: _questionScrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 20.h),
                children: [
                  if (isListeningSection) ...[
                    HskExamListeningAudioCard(
                      audioAssetPath: sectionAudioPath,
                      isAudioPlaying: _isAudioPlaying,
                      audioDuration: _audioDuration,
                      audioPosition: _audioPosition,
                      onToggleAudio: _toggleAudio,
                      formatDuration: _formatDuration,
                    ),
                    SizedBox(height: 12.h),
                  ],
                  ...currentSection.questions.map((question) {
                    return HskExamQuestionCard(
                      question: question,
                      selectedAnswer: _selectedAnswers[question.questionId],
                      onOptionSelected: (option) {
                        setState(() {
                          _selectedAnswers[question.questionId] = option;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isListeningSection(HskExamSection section) {
    final skill = section.skill.toLowerCase();
    return skill.contains('listen');
  }

  ImageProvider _buildImageProvider(String imagePath) {
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }
    return AssetImage(imagePath);
  }

  Widget _buildQuestionImage(
    String imagePath, {
    required double imageHeight,
    required VoidCallback onTap,
  }) {
    final imageProvider = _buildImageProvider(imagePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    color: AppColors.backgroundWhite,
                    child: Text(
                      'Không tải được ảnh minh họa: $imagePath',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Icon(
                    Icons.zoom_out_map_rounded,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQuestionImageViewer(String imagePath) async {
    final imageProvider = _buildImageProvider(imagePath);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.all(12.w),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Padding(
                          padding: EdgeInsets.all(14.w),
                          child: Text(
                            'Không tải được ảnh minh họa.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8.w,
                top: 8.h,
                child: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
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

    final data = await _loadAudioBytes(audioAssetPath);
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

  Future<ByteData> _loadAudioBytes(String audioAssetPath) async {
    try {
      return await rootBundle.load(audioAssetPath);
    } catch (_) {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final manifestMap = jsonDecode(manifestRaw) as Map<String, dynamic>;
      final fileName = audioAssetPath.split('/').last;

      final matchedKey = manifestMap.keys.cast<String?>().firstWhere(
        (key) => key != null && key.endsWith('/$fileName'),
        orElse: () => null,
      );

      if (matchedKey == null) {
        rethrow;
      }

      return rootBundle.load(matchedKey);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
      if (selected != null &&
          selected.toLowerCase() == question.correctAnswer.toLowerCase()) {
        correctCount++;
      } else {
        final selectedLabel = (selected == null || selected.trim().isEmpty)
            ? 'Chưa làm'
            : selected;
        wrongLines.add(
          'Câu ${question.questionId}: Bạn chọn $selectedLabel - Đúng: ${question.correctAnswer}',
        );
      }
    }

    final unanswered = questions.length - _selectedAnswers.length;
    final scoreOn10 = questions.isEmpty
        ? 0.0
        : ((correctCount / questions.length) * 10).clamp(0, 10).toDouble();
    final attemptNumber = await _peekNextAttemptNumber();
    if (!mounted) {
      _isSubmitting = false;
      return;
    }

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
                  const Text('Đã hết thời gian, hệ thống tự động nộp bài.'),
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

    final attemptRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('exam_attempts')
        .doc(widget.examId);
    final userRef = _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final attemptSnapshot = await transaction.get(attemptRef);
      final alreadyCompleted =
          (attemptSnapshot.data()?['completed'] ?? false) == true;
      final currentAttemptCount =
          (attemptSnapshot.data()?['attempt_count'] as num?)?.toInt() ?? 0;
      final nextAttemptCount = currentAttemptCount + 1;

      transaction.set(attemptRef, {
        'exam_id': widget.examId,
        'exam_code': exam.examCode,
        'level': exam.level,
        'completed': true,
        'attempt_count': nextAttemptCount,
        'last_attempt_number': nextAttemptCount,
        'correct_count': correctCount,
        'total_questions': totalQuestions,
        'score_10': scoreOn10,
        'completed_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!alreadyCompleted) {
        transaction.set(userRef, {
          'hsk_exam_completed_count': FieldValue.increment(1),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<int> _peekNextAttemptNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 1;
    }
    final snap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('exam_attempts')
        .doc(widget.examId)
        .get();
    final current = (snap.data()?['attempt_count'] as num?)?.toInt() ?? 0;
    return current + 1;
  }
}
