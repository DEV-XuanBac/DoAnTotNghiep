import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hanziilearnapp/app/datasource/repository/review_repository.dart';

class ReviewProvider extends ChangeNotifier {
  ReviewProvider({FirebaseAuth? auth, IReviewRepository? repository})
    : _auth = auth ?? FirebaseAuth.instance,
      _repo = repository ?? ReviewRepository();

  final FirebaseAuth _auth;
  final IReviewRepository _repo;

  bool reviewCompleted = false;
  Map<String, dynamic>? reviewResult;
  final Map<String, double> topicCompletionPercent = <String, double>{};

  bool isTopicCompleted(String topic) {
    return topicCompletionPercent[topic] != null;
  }

  double getTopicCompletionPercent(String topic) {
    return topicCompletionPercent[topic] ?? 0.0;
  }

  void clearCurrent() {
    reviewCompleted = false;
    reviewResult = null;
    notifyListeners();
  }

  Future<void> loadReviewResult({
    required String level,
    required String topic,
  }) async {
    final user = _auth.currentUser;
    reviewCompleted = false;
    reviewResult = null;
    if (user == null) {
      notifyListeners();
      return;
    }

    final data = await _repo.fetchReviewDoc(
      userId: user.uid,
      level: level,
      topic: topic,
    );
    if (data == null) {
      notifyListeners();
      return;
    }

    reviewCompleted = data['completed'] == true;
    reviewResult = data;
    if (reviewCompleted) {
      final percent =
          (data['completionPercent'] as num?)?.toDouble() ??
          _computePercentFromData(data);
      topicCompletionPercent[topic] = percent;
    }
    notifyListeners();
  }

  Future<void> loadTopicCompletionByLevel(String level) async {
    final user = _auth.currentUser;
    topicCompletionPercent.clear();
    if (user == null) {
      notifyListeners();
      return;
    }

    final map = await _repo.fetchCompletedTopicPercents(
      userId: user.uid,
      level: level,
    );
    topicCompletionPercent.addAll(map);
    notifyListeners();
  }

  Future<void> saveReviewResult({
    required String level,
    required String topic,
    required int totalQuestions,
    required int correctAnswers,
    required List<Map<String, dynamic>> wrongItems,
    required List<Map<String, dynamic>> reviewedWords,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Vui lòng đăng nhập để lưu kết quả ôn tập.');
    }

    final alreadyDone = await _repo.isTopicAlreadyCompleted(
      userId: user.uid,
      level: level,
      topic: topic,
    );
    if (alreadyDone) {
      throw StateError('Chủ đề này đã hoàn thành, không thể làm lại.');
    }

    final completionPercent = totalQuestions == 0
        ? 0.0
        : (correctAnswers / totalQuestions) * 100;
    final payload = <String, dynamic>{
      'userId': user.uid,
      'hskLevel': level,
      'topic': topic,
      'completed': true,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': totalQuestions - correctAnswers,
      'completionPercent': completionPercent,
      'wrongItems': wrongItems,
      'reviewedWords': reviewedWords,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _repo.saveReviewPayload(
      userId: user.uid,
      level: level,
      topic: topic,
      payload: payload,
    );
    reviewCompleted = true;
    reviewResult = payload;
    topicCompletionPercent[topic] = completionPercent;
    notifyListeners();
  }

  double _computePercentFromData(Map<String, dynamic> data) {
    final total = (data['totalQuestions'] as num?)?.toDouble() ?? 0;
    final correct = (data['correctAnswers'] as num?)?.toDouble() ?? 0;
    if (total <= 0) {
      return 0;
    }
    return (correct / total) * 100;
  }
}
