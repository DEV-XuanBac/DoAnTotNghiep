import 'package:cloud_firestore/cloud_firestore.dart';

/// Truy cập collection `soTayOnTap` (kết quả ôn tập theo chủ đề).
abstract class IReviewRepository {
  Future<Map<String, dynamic>?> fetchReviewDoc({
    required String userId,
    required String level,
    required String topic,
  });

  Future<Map<String, double>> fetchCompletedTopicPercents({
    required String userId,
    required String level,
  });

  Future<bool> isTopicAlreadyCompleted({
    required String userId,
    required String level,
    required String topic,
  });

  Future<void> saveReviewPayload({
    required String userId,
    required String level,
    required String topic,
    required Map<String, dynamic> payload,
  });
}

class ReviewRepository implements IReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'soTayOnTap';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  static String slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\u00C0-\u1EF9\u4e00-\u9fff]'), '');
  }

  String _docId(String userId, String level, String topic) =>
      '${userId}_${slug(level)}_${slug(topic)}';

  @override
  Future<Map<String, dynamic>?> fetchReviewDoc({
    required String userId,
    required String level,
    required String topic,
  }) async {
    final doc = await _ref.doc(_docId(userId, level, topic)).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data();
  }

  @override
  Future<Map<String, double>> fetchCompletedTopicPercents({
    required String userId,
    required String level,
  }) async {
    final result = await _ref
        .where('userId', isEqualTo: userId)
        .where('hskLevel', isEqualTo: level)
        .where('completed', isEqualTo: true)
        .get();

    final map = <String, double>{};
    for (final doc in result.docs) {
      final data = doc.data();
      final topic = (data['topic'] ?? '').toString().trim();
      if (topic.isEmpty) {
        continue;
      }
      final percent =
          (data['completionPercent'] as num?)?.toDouble() ??
          _computePercentFromData(data);
      map[topic] = percent;
    }
    return map;
  }

  @override
  Future<bool> isTopicAlreadyCompleted({
    required String userId,
    required String level,
    required String topic,
  }) async {
    final existed = await _ref.doc(_docId(userId, level, topic)).get();
    return existed.exists && (existed.data()?['completed'] == true);
  }

  @override
  Future<void> saveReviewPayload({
    required String userId,
    required String level,
    required String topic,
    required Map<String, dynamic> payload,
  }) {
    return _ref
        .doc(_docId(userId, level, topic))
        .set(payload, SetOptions(merge: true));
  }

  static double _computePercentFromData(Map<String, dynamic> data) {
    final total = (data['totalQuestions'] as num?)?.toDouble() ?? 0;
    final correct = (data['correctAnswers'] as num?)?.toDouble() ?? 0;
    if (total <= 0) {
      return 0;
    }
    return (correct / total) * 100;
  }
}
