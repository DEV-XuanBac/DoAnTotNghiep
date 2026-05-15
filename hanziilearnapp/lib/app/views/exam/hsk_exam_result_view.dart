import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/router/app_router.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/datasource/repository/exam_attempt_repository.dart';
import 'package:hanziilearnapp/app/datasource/repository/hsk_exam_repository.dart';
import 'package:hanziilearnapp/app/models/exam_attempt_model.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_states.dart';
import 'package:provider/provider.dart';

class HskExamResultView extends StatefulWidget {
  const HskExamResultView({
    super.key,
    required this.examId,
    required this.level,
  });

  final String examId;
  final String level;

  @override
  State<HskExamResultView> createState() => _HskExamResultViewState();
}

class _HskExamResultViewState extends State<HskExamResultView> {
  late final IExamAttemptRepository _attemptRepo;
  late final IHskExamRepository _examRepo;
  late Future<_ResultPayload> _payloadFuture;
  bool _didUpdateAttempt = false;

  @override
  void initState() {
    super.initState();
    _attemptRepo = context.read<IExamAttemptRepository>();
    _examRepo = context.read<IHskExamRepository>();
    _payloadFuture = _loadPayload();
  }

  Future<_ResultPayload> _loadPayload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('not_logged_in');
    }

    final results = await Future.wait([
      _attemptRepo.getAttemptDetail(userId: user.uid, examId: widget.examId),
      _examRepo.getExamDetail(widget.examId),
    ]);

    final attempt = results[0] as ExamAttemptDetail?;
    final exam = results[1] as HskExamDetail;
    if (attempt == null) {
      throw StateError('no_attempt');
    }
    return _ResultPayload(attempt: attempt, exam: exam);
  }

  void _reload() {
    setState(() {
      _payloadFuture = _loadPayload();
    });
  }

  Future<void> _onRetry() async {
    final didComplete = await AppRouter.pushHskExamTake(
      context,
      examId: widget.examId,
      level: widget.level,
    );
    if (!mounted || didComplete != true) {
      return;
    }
    _didUpdateAttempt = true;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        title: const Text('Kết quả bài thi'),
        backgroundColor: context.palette.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _didUpdateAttempt),
        ),
      ),
      body: FutureBuilder<_ResultPayload>(
          future: _payloadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const HskExamLoadingState();
            }

            if (snapshot.hasError) {
              final err = snapshot.error;
              if (err is StateError && err.message == 'not_logged_in') {
                return const HskExamErrorState(
                  message: 'Vui lòng đăng nhập để xem kết quả.',
                );
              }
              if (err is StateError && err.message == 'no_attempt') {
                return const HskExamErrorState(
                  message: 'Chưa có kết quả cho đề thi này.',
                );
              }
              return const HskExamErrorState(
                message: 'Không thể tải kết quả. Vui lòng thử lại.',
              );
            }

            final payload = snapshot.data!;
            return _buildContent(payload);
          },
        ),
    );
  }

  Widget _buildContent(_ResultPayload payload) {
    final attempt = payload.attempt;
    final exam = payload.exam;
    final questionsById = {
      for (final q in exam.allQuestions) q.questionId: q,
    };
    final wrongResults = attempt.wrongResults;
    final hasLegacyAttempt =
        attempt.wrongCount > 0 && wrongResults.isEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 14.h),
            children: [
              _ScoreSummaryCard(
                title: exam.title,
                attemptNumber: attempt.attemptNumber,
                scoreOutOf10: attempt.scoreOutOf10,
                correctCount: attempt.correctCount,
                totalQuestions: attempt.totalQuestions,
                wrongCount: attempt.wrongCount,
              ),
              SizedBox(height: 16.h),
              if (hasLegacyAttempt)
                Text(
                  'Đề này được làm trước khi lưu chi tiết câu trả lời. '
                  'Nhấn "Làm lại" để xem đáp án từng câu sau lần làm mới.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: context.palette.secondaryText,
                  ),
                )
              else if (wrongResults.isEmpty)
                Text(
                  'Chúc mừng! Bạn đã trả lời đúng tất cả các câu.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.palette.greenText,
                  ),
                )
              else ...[
                Text(
                  'Các câu sai (${wrongResults.length})',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: context.palette.primaryText,
                  ),
                ),
                SizedBox(height: 10.h),
                ...wrongResults.map((result) {
                  final question = questionsById[result.questionId];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: _WrongQuestionCard(
                      result: result,
                      question: question,
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 14.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Làm lại'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreSummaryCard extends StatelessWidget {
  const _ScoreSummaryCard({
    required this.title,
    required this.attemptNumber,
    required this.scoreOutOf10,
    required this.correctCount,
    required this.totalQuestions,
    required this.wrongCount,
  });

  final String title;
  final int attemptNumber;
  final double scoreOutOf10;
  final int correctCount;
  final int totalQuestions;
  final int wrongCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.palette.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.palette.borderDefault.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: context.palette.primaryText,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Lần làm thứ ${attemptNumber <= 0 ? 1 : attemptNumber}',
            style: TextStyle(
              fontSize: 13.sp,
              color: context.palette.secondaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Điểm: ${scoreOutOf10.toStringAsFixed(1)}/10',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: context.palette.greenText,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Đúng: $correctCount/$totalQuestions · Sai: $wrongCount câu',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: context.palette.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _WrongQuestionCard extends StatelessWidget {
  const _WrongQuestionCard({
    required this.result,
    this.question,
  });

  final ExamQuestionResult result;
  final HskExamQuestion? question;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _formatSelected(result.selectedAnswer);
    final questionText = question?.questionText.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.palette.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.palette.errorText.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu ${result.questionId}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: context.palette.errorText,
            ),
          ),
          if (questionText != null && questionText.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              questionText,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.palette.primaryText,
              ),
            ),
          ],
          SizedBox(height: 8.h),
          _AnswerRow(
            label: 'Bạn chọn',
            value: selectedLabel,
            valueColor: context.palette.errorText,
          ),
          SizedBox(height: 4.h),
          _AnswerRow(
            label: 'Đáp án đúng',
            value: result.correctAnswer,
            valueColor: context.palette.greenText,
          ),
        ],
      ),
    );
  }

  static String _formatSelected(String? selected) {
    if (selected == null || selected.trim().isEmpty) {
      return 'Chưa làm';
    }
    return selected;
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13.sp, color: context.palette.secondaryText),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPayload {
  const _ResultPayload({required this.attempt, required this.exam});

  final ExamAttemptDetail attempt;
  final HskExamDetail exam;
}
