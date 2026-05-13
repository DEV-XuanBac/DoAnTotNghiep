import 'package:cloud_firestore/cloud_firestore.dart';

/// Snapshot 1 lượt thi của user cho 1 đề HSK.
class ExamAttemptStatus {
  const ExamAttemptStatus({
    required this.isCompleted,
    this.scoreOutOf10,
    this.attemptCount = 0,
  });

  final bool isCompleted;
  final double? scoreOutOf10;
  final int attemptCount;
}

/// Truy cập sub-collection `users/{uid}/exam_attempts` để lưu lịch sử
/// làm đề HSK của user, đồng thời cập nhật counter `hsk_exam_completed_count`
/// trên document user khi lần đầu hoàn thành 1 đề.
abstract class IExamAttemptRepository {
  /// Số lần làm tiếp theo cho 1 đề (current + 1, mặc định 1 nếu chưa có).
  Future<int> peekNextAttemptNumber({
    required String userId,
    required String examId,
  });

  /// Lưu kết quả 1 lượt thi (transaction): set/update exam_attempts/{examId}
  /// và tăng counter trên user nếu lần đầu completed.
  Future<void> saveExamCompletion({
    required String userId,
    required String examId,
    required String examCode,
    required String level,
    required int correctCount,
    required int totalQuestions,
    required double scoreOn10,
  });

  /// Lấy map `examId -> ExamAttemptStatus` cho user theo level.
  Future<Map<String, ExamAttemptStatus>> listAttemptsForUserByLevel({
    required String userId,
    required String level,
  });
}

class ExamAttemptRepository implements IExamAttemptRepository {
  ExamAttemptRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _attemptRef(
    String userId,
    String examId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('exam_attempts')
        .doc(examId);
  }

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection('users').doc(userId);

  @override
  Future<int> peekNextAttemptNumber({
    required String userId,
    required String examId,
  }) async {
    final snap = await _attemptRef(userId, examId).get();
    final current = (snap.data()?['attempt_count'] as num?)?.toInt() ?? 0;
    return current + 1;
  }

  @override
  Future<void> saveExamCompletion({
    required String userId,
    required String examId,
    required String examCode,
    required String level,
    required int correctCount,
    required int totalQuestions,
    required double scoreOn10,
  }) {
    final attemptRef = _attemptRef(userId, examId);
    final userRef = _userRef(userId);
    return _firestore.runTransaction((transaction) async {
      final attemptSnapshot = await transaction.get(attemptRef);
      final alreadyCompleted =
          (attemptSnapshot.data()?['completed'] ?? false) == true;
      final currentAttemptCount =
          (attemptSnapshot.data()?['attempt_count'] as num?)?.toInt() ?? 0;
      final nextAttemptCount = currentAttemptCount + 1;

      transaction.set(attemptRef, {
        'exam_id': examId,
        'exam_code': examCode,
        'level': level,
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

  @override
  Future<Map<String, ExamAttemptStatus>> listAttemptsForUserByLevel({
    required String userId,
    required String level,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exam_attempts')
        .where('level', isEqualTo: level)
        .get();

    final attempts = <String, ExamAttemptStatus>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final examId = (data['exam_id'] ?? '').toString();
      if (examId.isEmpty) {
        continue;
      }
      final completed = (data['completed'] ?? false) == true;
      final rawScore = data['score_10'];
      final rawAttemptCount = data['attempt_count'];
      attempts[examId] = ExamAttemptStatus(
        isCompleted: completed,
        scoreOutOf10: rawScore is num ? rawScore.toDouble() : null,
        attemptCount: rawAttemptCount is num ? rawAttemptCount.toInt() : 0,
      );
    }
    return attempts;
  }
}
