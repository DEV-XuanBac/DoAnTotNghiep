import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

/// Truy cập từ điển trên Firestore.
class DictionaryService {
  final db = FirebaseFirestore.instance;

  Future<List<Word>> searchWord(String keyWord) async {
    final result = await db
        .collection('dictionary')
        .where('hanzi', isGreaterThanOrEqualTo: keyWord)
        .limit(10)
        .get();
    return result.docs.map(_toWord).toList();
  }

  Future<List<Word>> getWordsByHskLevel(String hskLevel) async {
    final result = await db
        .collection('dictionary')
        .where('hskLevel', isEqualTo: hskLevel)
        .get();

    final words = result.docs.map(_toWord).toList();
    words.sort((a, b) {
      final left = int.tryParse(a.stt) ?? 0;
      final right = int.tryParse(b.stt) ?? 0;
      return left.compareTo(right);
    });

    return words;
  }

  Future<int> getWordCountByHskLevel(String hskLevel) async {
    final result = await db
        .collection('dictionary')
        .where('hskLevel', isEqualTo: hskLevel)
        .get();
    return result.docs.length;
  }

  Word _toWord(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Word(
      id: doc.id,
      hanzi: _toString(data['hanzi']),
      pinyin: _toString(data['pinyin']),
      meaning: _toString(data['meaning']),
      hskLevel: _toString(data['hskLevel']).isNotEmpty
          ? _toString(data['hskLevel'])
          : _toString(data['level']),
      stt: _toString(data['stt']),
      topic: _toString(data['topic']),
      ttsUrl: _toString(data['ttsUrl']).isNotEmpty
          ? _toString(data['ttsUrl'])
          : _toString(data['tts_url']),
      exampleHanzi: _toString(data['exampleHanzi']),
      examplePinyin: _toString(data['examplePinyin']),
      exampleMeaning: _toString(data['exampleMeaning']),
    );
  }

  String _toString(Object? value) {
    return value?.toString() ?? '';
  }
}
