import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/datasource/network_services/hsk_exam_service.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

class HskExamTakeView extends StatefulWidget {
  const HskExamTakeView({super.key, required this.examId, required this.level});

  final String examId;
  final String level;

  @override
  State<HskExamTakeView> createState() => _HskExamTakeViewState();
}

class _HskExamTakeViewState extends State<HskExamTakeView> {
  final HskExamService _examService = HskExamService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final Future<HskExamDetail> _examFuture;
  late final AudioPlayer _audioPlayer;

  int _currentSectionIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isAudioPlaying = false;
  String? _currentAudioSource;

  @override
  void initState() {
    super.initState();
    _examFuture = _examService.getExamDetail(widget.examId);
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
      ),
      body: FutureBuilder<HskExamDetail>(
        future: _examFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'Không thể tải đề thi. Vui lòng thử lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            );
          }

          final exam = snapshot.data!;
          final sections = exam.sections;
          final questions = exam.allQuestions;
          if (questions.isEmpty || sections.isEmpty) {
            return Center(
              child: Text(
                'Đề thi chưa có câu hỏi.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14.sp,
                ),
              ),
            );
          }

          final currentSection = sections[_currentSectionIndex];
          final isListeningSection = _isListeningSection(currentSection);
          final sectionAudioPath = _resolveSectionAudioPath(
            exam,
            currentSection,
          );
          final progressText =
              'Phần ${_currentSectionIndex + 1}/${sections.length} - Đã làm ${_selectedAnswers.length}/${questions.length} câu';

          return Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                        if (currentSection.questionImage != null) ...[
                          _buildQuestionImage(currentSection.questionImage!),
                          SizedBox(height: 10.h),
                        ],
                        if (isListeningSection) ...[
                          _buildListeningAudioCard(sectionAudioPath),
                          SizedBox(height: 12.h),
                        ],
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.borderDefault.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...currentSection.questions.map(
                                (question) => _buildQuestionCard(question),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _currentSectionIndex > 0
                            ? () {
                                _goToSection(exam, _currentSectionIndex - 1);
                              }
                            : null,
                        child: const Text('Phần trước'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentSectionIndex < sections.length - 1
                            ? () {
                                _goToSection(exam, _currentSectionIndex + 1);
                              }
                            : () => _submitExam(exam),
                        child: Text(
                          _currentSectionIndex < sections.length - 1
                              ? 'Phần tiếp'
                              : 'Nộp bài',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isListeningSection(HskExamSection section) {
    final skill = section.skill.toLowerCase();
    return skill.contains('listen');
  }

  Widget _buildQuestionCard(HskExamQuestion question) {
    final selected = _selectedAnswers[question.questionId];
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.borderDefault.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu ${question.questionId} (${question.code})',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
            if (question.questionText.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                question.questionText,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            SizedBox(height: 8.h),
            ...question.options.map((option) {
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: () {
                    setState(() {
                      _selectedAnswers[question.questionId] = option;
                    });
                  },
                  child: Ink(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 9.h,
                    ),
                    decoration: BoxDecoration(
                      color: selected == option
                          ? AppColors.lightCardBackground
                          : AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: selected == option
                            ? AppColors.bottomButton
                            : AppColors.borderDefault.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected == option
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 17.sp,
                          color: selected == option
                              ? AppColors.bottomButton
                              : AppColors.secondaryText,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionImage(String imagePath) {
    final imageProvider = imagePath.startsWith('http')
        ? NetworkImage(imagePath)
        : AssetImage(imagePath) as ImageProvider;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Image(
        image: imageProvider,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            color: AppColors.backgroundWhite,
            child: Text(
              'Không tải được ảnh minh họa: $imagePath',
              style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListeningAudioCard(String? audioAssetPath) {
    final maxMs = _audioDuration.inMilliseconds > 0
        ? _audioDuration.inMilliseconds.toDouble()
        : 1.0;
    final valueMs = _audioPosition.inMilliseconds
        .clamp(0, maxMs.toInt())
        .toDouble();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.borderDefault.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listening (câu 1-20): nghe file audio để làm bài',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          if (audioAssetPath == null) ...[
            Text(
              'Phần nghe này chưa được cập nhật file audio.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
            ),
          ] else ...[
            Row(
              children: [
                IconButton(
                  onPressed: () => _toggleAudio(audioAssetPath),
                  icon: Icon(
                    _isAudioPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: AppColors.bottomButton,
                    size: 30.sp,
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    minHeight: 4.h,
                    borderRadius: BorderRadius.circular(99.r),
                    value: maxMs <= 1 ? 0 : (valueMs / maxMs).clamp(0.0, 1.0),
                  ),
                ),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}',
              style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
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

  void _submitExam(HskExamDetail exam) {
    final questions = exam.allQuestions;
    if (questions.isEmpty) {
      return;
    }

    var correctCount = 0;
    for (final question in questions) {
      final selected = _selectedAnswers[question.questionId];
      if (selected != null &&
          selected.toLowerCase() == question.correctAnswer.toLowerCase()) {
        correctCount++;
      }
    }

    final unanswered = questions.length - _selectedAnswers.length;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kết quả bài thi'),
          content: Text(
            'Đúng: $correctCount/${questions.length}\n'
            'Chưa làm: $unanswered câu',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Xem lại bài'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _recordExamCompletion(exam);
                Navigator.pop(context);
              },
              child: const Text('Hoàn thành'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recordExamCompletion(HskExamDetail exam) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final attemptRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('exam_attempts')
        .doc(widget.examId);
    final userRef = _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final attemptSnapshot = await transaction.get(attemptRef);
      final alreadyCompleted = (attemptSnapshot.data()?['completed'] ?? false) ==
          true;

      transaction.set(attemptRef, {
        'exam_id': widget.examId,
        'exam_code': exam.examCode,
        'level': exam.level,
        'completed': true,
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
}
