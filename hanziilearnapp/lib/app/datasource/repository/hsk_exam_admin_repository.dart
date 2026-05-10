import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanziilearnapp/app/models/parsed_hsk_exam_model.dart';

abstract class IHskExamAdminRepository {
  Future<void> upload({
    required ParsedHskExam parsed,
    String? sourceFileName,
  });
}

class HskExamAdminRepository implements IHskExamAdminRepository {
  HskExamAdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'hsk_exams';

  @override
  Future<void> upload({
    required ParsedHskExam parsed,
    String? sourceFileName,
  }) async {
    final id = '${parsed.level}_${parsed.examCode}'.toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '_',
    );

    await _firestore.collection(_collection).doc(id).set({
      'examCode': parsed.examCode,
      'level': parsed.level,
      'title': parsed.title,
      'totalQuestions': parsed.totalQuestions,
      'sectionCount': parsed.sectionCount,
      'sourceFileName': sourceFileName ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'examData': parsed.normalizedJson,
    }, SetOptions(merge: true));
  }
}
