import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

class HskExamService {
  HskExamService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'hsk_exams';

  Future<List<HskExam>> getExamsByLevel(String level) async {
    final normalizedLevel = level.toUpperCase();
    final snapshot = await _firestore
        .collection(_collection)
        .where('level', isEqualTo: normalizedLevel)
        .get();

    final exams =
        snapshot.docs
            .map((doc) => HskExam.fromFirestore(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.examCode.compareTo(b.examCode));

    return exams;
  }

  Future<HskExamDetail> getExamDetail(String examId) async {
    final doc = await _firestore.collection(_collection).doc(examId).get();
    if (!doc.exists) {
      throw Exception('Không tìm thấy đề thi trên Firestore.');
    }

    final data = doc.data();
    if (data == null) {
      throw Exception('Dữ liệu đề thi trống.');
    }

    final examData = data['examData'];
    if (examData is! Map<String, dynamic>) {
      throw const FormatException(
        'Dữ liệu examData không đúng định dạng JSON object.',
      );
    }

    return HskExamDetail.fromJson(examData);
  }
}
