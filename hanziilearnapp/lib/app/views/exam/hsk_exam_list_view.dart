import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/datasource/network_services/hsk_exam_service.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';
import 'package:hanziilearnapp/app/views/exam/hsk_exam_take_view.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_list_item.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_states.dart';

class HskExamListView extends StatefulWidget {
  const HskExamListView({super.key, required this.hskLevel});

  final String hskLevel;

  @override
  State<HskExamListView> createState() => _HskExamListViewState();
}

class _HskExamListViewState extends State<HskExamListView> {
  late Future<_ExamListPayload> _examFuture;
  final HskExamService _examService = HskExamService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _examFuture = _loadExamsWithAttemptStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Danh sách đề thi ${widget.hskLevel}'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: FutureBuilder<_ExamListPayload>(
        future: _examFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const HskExamLoadingState();
          }

          if (snapshot.hasError) {
            return const HskExamErrorState(
              message: 'Không thể tải danh sách đề thi. Vui lòng thử lại.',
            );
          }

          final payload = snapshot.data;
          final exams = payload?.exams ?? [];
          final attemptsByExamId = payload?.attemptsByExamId ?? const {};
          if (exams.isEmpty) {
            return HskExamEmptyState(
              message:
                  'Hiện đề thi cấp độ ${widget.hskLevel} chưa được cập nhật',
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(14.w),
            itemCount: exams.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final exam = exams[index];
              final attempt = attemptsByExamId[exam.id];
              return HskExamListItem(
                exam: exam,
                isCompleted: attempt?.isCompleted ?? false,
                scoreOutOf10: attempt?.scoreOutOf10,
                attemptCount: attempt?.attemptCount ?? 0,
                onTap: () {
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HskExamTakeView(
                        examId: exam.id,
                        level: widget.hskLevel,
                      ),
                    ),
                  ).then((didComplete) {
                    if (didComplete == true && mounted) {
                      setState(() {
                        _examFuture = _loadExamsWithAttemptStatus();
                      });
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<_ExamListPayload> _loadExamsWithAttemptStatus() async {
    final exams = await _examService.getExamsByLvl(widget.hskLevel);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _ExamListPayload(exams: exams, attemptsByExamId: const {});
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('exam_attempts')
        .where('level', isEqualTo: widget.hskLevel)
        .get();

    final attempts = <String, _ExamAttemptStatus>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final examId = (data['exam_id'] ?? '').toString();
      if (examId.isEmpty) {
        continue;
      }
      final completed = (data['completed'] ?? false) == true;
      final rawScore = data['score_10'];
      final rawAttemptCount = data['attempt_count'];
      final score = rawScore is num ? rawScore.toDouble() : null;
      final attemptCount = rawAttemptCount is num ? rawAttemptCount.toInt() : 0;
      attempts[examId] = _ExamAttemptStatus(
        isCompleted: completed,
        scoreOutOf10: score,
        attemptCount: attemptCount,
      );
    }

    return _ExamListPayload(exams: exams, attemptsByExamId: attempts);
  }
}

class _ExamAttemptStatus {
  const _ExamAttemptStatus({
    required this.isCompleted,
    this.scoreOutOf10,
    this.attemptCount = 0,
  });

  final bool isCompleted;
  final double? scoreOutOf10;
  final int attemptCount;
}

class _ExamListPayload {
  const _ExamListPayload({required this.exams, required this.attemptsByExamId});

  final List<HskExam> exams;
  final Map<String, _ExamAttemptStatus> attemptsByExamId;
}
