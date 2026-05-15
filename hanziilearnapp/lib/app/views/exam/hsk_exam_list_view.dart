import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/router/app_router.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/datasource/repository/exam_attempt_repository.dart';
import 'package:hanziilearnapp/app/datasource/repository/hsk_exam_repository.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_list_item.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_states.dart';
import 'package:provider/provider.dart';

class HskExamListView extends StatefulWidget {
  const HskExamListView({super.key, required this.hskLevel});

  final String hskLevel;

  @override
  State<HskExamListView> createState() => _HskExamListViewState();
}

class _HskExamListViewState extends State<HskExamListView> {
  late Future<_ExamListPayload> _examFuture;
  late final IHskExamRepository _examRepo;
  late final IExamAttemptRepository _attemptRepo;

  @override
  void initState() {
    super.initState();
    _examRepo = context.read<IHskExamRepository>();
    _attemptRepo = context.read<IExamAttemptRepository>();
    _examFuture = _loadExamsWithAttemptStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        title: Text('Danh sách đề thi ${widget.hskLevel}'),
        backgroundColor: context.palette.backgroundLight,
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
                onTap: () => _onExamTap(exam, attempt),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onExamTap(HskExam exam, ExamAttemptStatus? attempt) async {
    if (exam.id.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không mở được đề thi. Vui lòng thử lại.'),
        ),
      );
      return;
    }

    final isCompleted = attempt?.isCompleted ?? false;
    final didUpdate = isCompleted
        ? await AppRouter.pushHskExamResultFromRoot(
            examId: exam.id,
            level: widget.hskLevel,
          )
        : await AppRouter.pushHskExamTakeFromRoot(
            examId: exam.id,
            level: widget.hskLevel,
          );

    if (!mounted) {
      return;
    }
    if (didUpdate == true) {
      setState(() {
        _examFuture = _loadExamsWithAttemptStatus();
      });
    }
  }

  Future<_ExamListPayload> _loadExamsWithAttemptStatus() async {
    final exams = await _examRepo.getExamsByLevel(widget.hskLevel);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _ExamListPayload(exams: exams, attemptsByExamId: const {});
    }

    final attempts = await _attemptRepo.listAttemptsForUserByLevel(
      userId: user.uid,
      level: widget.hskLevel,
    );

    return _ExamListPayload(exams: exams, attemptsByExamId: attempts);
  }
}

class _ExamListPayload {
  const _ExamListPayload({required this.exams, required this.attemptsByExamId});

  final List<HskExam> exams;
  final Map<String, ExamAttemptStatus> attemptsByExamId;
}
