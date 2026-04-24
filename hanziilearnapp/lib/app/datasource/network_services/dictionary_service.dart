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

  Future<List<Word>> searchByHanziPrefix(
    String keyword, {
    int limit = 12,
  }) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final result = await db
        .collection('dictionary')
        .where('hanzi', isGreaterThanOrEqualTo: normalized)
        .where('hanzi', isLessThanOrEqualTo: '$normalized\uf8ff')
        .limit(limit)
        .get();

    return result.docs.map(_toWord).toList();
  }

  Future<List<Word>> searchByMeaningPrefix(
    String keyword, {
    int limit = 12,
  }) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final result = await db
        .collection('dictionary')
        .where('meaning', isGreaterThanOrEqualTo: normalized)
        .where('meaning', isLessThanOrEqualTo: '$normalized\uf8ff')
        .limit(limit)
        .get();

    return result.docs.map(_toWord).toList();
  }

  Future<List<Word>> getRelatedWords(Word word, {int limit = 10}) async {
    Query<Map<String, dynamic>> query;
    if (word.topic.trim().isNotEmpty) {
      query = db.collection('dictionary').where('topic', isEqualTo: word.topic);
    } else {
      query = db
          .collection('dictionary')
          .where('hskLevel', isEqualTo: word.hskLevel);
    }

    final result = await query.limit(limit + 1).get();
    final words = result.docs
        .map(_toWord)
        .where((item) => item.id != word.id)
        .take(limit)
        .toList();
    return words;
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

  Future<List<String>> getTopicsByHskLevel(String hskLevel) async {
    final result = await db
        .collection('dictionary')
        .where('hskLevel', isEqualTo: hskLevel)
        .get();

    final topics = result.docs
        .map((doc) => _toString(doc.data()['topic']).trim())
        .where((topic) => topic.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return topics;
  }

  Future<List<Word>> getWordsByHskLevelAndTopic(
    String hskLevel,
    String topic,
  ) async {
    final normalizedTopic = topic.trim();
    Query<Map<String, dynamic>> query = db
        .collection('dictionary')
        .where('hskLevel', isEqualTo: hskLevel);

    if (normalizedTopic.isNotEmpty) {
      query = query.where('topic', isEqualTo: normalizedTopic);
    }

    final result = await query.get();
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
