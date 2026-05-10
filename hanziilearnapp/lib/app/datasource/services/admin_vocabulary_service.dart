import 'package:cloud_firestore/cloud_firestore.dart';

class AdminVocabularyService {
  AdminVocabularyService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Map<String, dynamic>>> watchWordsByLvl(String hskLevel) {
    return _firestore
        .collection('dictionary')
        .where('hskLevel', isEqualTo: hskLevel)
        .snapshots()
        .map((snapshot) {
          final rows = snapshot.docs.map((doc) => doc.data()).toList();
          rows.sort((a, b) {
            final left = int.tryParse((a['stt'] ?? '').toString()) ?? 0;
            final right = int.tryParse((b['stt'] ?? '').toString()) ?? 0;
            return left.compareTo(right);
          });
          return rows;
        });
  }

  Future<int> nextStt(String hskLevel) async {
    final rs = await _firestore
        .collection('dictionary')
        .where('hskLevel', isEqualTo: hskLevel)
        .get();
    return rs.docs.length + 1;
  }

  Future<void> saveVocab({
    required String hskLevel,
    required String stt,
    required String hanzi,
    required String pinyin,
    required String meaning,
    required String topic,
    required String ttsUrl,
    required String exampleHanzi,
    required String examplePinyin,
    required String exampleMeaning,
  }) async {
    final docId = _buildDictionaryDocId(
      hskLevel: hskLevel,
      stt: stt,
      hanzi: hanzi,
    );

    await _firestore.collection('dictionary').doc(docId).set({
      'stt': stt,
      'level': hskLevel,
      'hskLevel': hskLevel,
      'hanzi': hanzi,
      'pinyin': pinyin,
      'meaning': meaning,
      'topic': topic,
      'ttsUrl': ttsUrl,
      'exampleHanzi': exampleHanzi,
      'examplePinyin': examplePinyin,
      'exampleMeaning': exampleMeaning,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _buildDictionaryDocId({
    required String hskLevel,
    required String stt,
    required String hanzi,
  }) {
    final segments = [hskLevel, stt, hanzi]
        .map(_slugify)
        .where((segment) => segment.isNotEmpty)
        .toList();
    return segments.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : segments.join('_');
  }

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\u4e00-\u9fff]'), '');
  }
}
