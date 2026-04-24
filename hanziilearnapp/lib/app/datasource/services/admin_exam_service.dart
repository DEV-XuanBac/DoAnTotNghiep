import 'package:cloud_firestore/cloud_firestore.dart';

class AdminExamService {
  AdminExamService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Map<String, dynamic>>> watchExamsByLevel(String level) {
    return _firestore
        .collection('hsk_exams')
        .where('level', isEqualTo: level)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).toList();
          docs.sort((a, b) {
            final left = (a['examCode'] ?? '').toString();
            final right = (b['examCode'] ?? '').toString();
            return left.compareTo(right);
          });
          return docs;
        });
  }
}
