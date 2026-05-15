import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

/// Truy cập collection `dictionary` (từ điển HSK).
abstract class IDictionaryRepository {
  Future<List<Word>> searchByHanziPrefix(String keyword, {int limit = 12});

  Future<List<Word>> searchByMeaningPrefix(String keyword, {int limit = 12});

  Future<List<Word>> getRelatedWords(Word word, {int limit = 10});

  Future<List<Word>> getWordsByHskLevel(String hskLevel);

  Future<List<String>> getTopicsByHskLevel(String hskLevel);

  Future<List<Word>> getWordsByHskLevelAndTopic(String hskLevel, String topic);

  Future<int> getWordCountByLvl(String hskLevel);

  /// Tìm gần đúng theo `hanzi >= keyword`.
  Future<List<Word>> searchWord(String keyword);
}

class DictionaryRepository implements IDictionaryRepository {
  DictionaryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'dictionary';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  @override
  Future<List<Word>> searchWord(String keyword) async {
    final result = await _ref
        .where('hanzi', isGreaterThanOrEqualTo: keyword)
        .limit(10)
        .get();
    return result.docs.map(_toWord).toList();
  }

  @override
  Future<List<Word>> searchByHanziPrefix(
    String keyword, {
    int limit = 12,
  }) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final result = await _ref
        .where('hanzi', isGreaterThanOrEqualTo: normalized)
        .where('hanzi', isLessThanOrEqualTo: '$normalized\uf8ff')
        .limit(limit)
        .get();
    return result.docs.map(_toWord).toList();
  }

  @override
  Future<List<Word>> searchByMeaningPrefix(
    String keyword, {
    int limit = 12,
  }) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final result = await _ref
        .where('meaning', isGreaterThanOrEqualTo: normalized)
        .where('meaning', isLessThanOrEqualTo: '$normalized\uf8ff')
        .limit(limit)
        .get();
    return result.docs.map(_toWord).toList();
  }

  @override
  Future<List<Word>> getRelatedWords(Word word, {int limit = 10}) async {
    Query<Map<String, dynamic>> query;
    if (word.topic.trim().isNotEmpty) {
      query = _ref.where('topic', isEqualTo: word.topic);
    } else {
      query = _ref.where('hskLevel', isEqualTo: word.hskLevel);
    }

    final result = await query.limit(limit + 1).get();
    return result.docs
        .map(_toWord)
        .where((item) => item.id != word.id)
        .take(limit)
        .toList();
  }

  @override
  Future<List<Word>> getWordsByHskLevel(String hskLevel) async {
    final result = await _ref.where('hskLevel', isEqualTo: hskLevel).get();
    return _sortedByStt(result.docs);
  }

  @override
  Future<List<String>> getTopicsByHskLevel(String hskLevel) async {
    final result = await _ref.where('hskLevel', isEqualTo: hskLevel).get();
    final topics =
        result.docs
            .map((doc) => _toString(doc.data()['topic']).trim())
            .where((topic) => topic.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return topics;
  }

  @override
  Future<List<Word>> getWordsByHskLevelAndTopic(
    String hskLevel,
    String topic,
  ) async {
    final normalizedTopic = topic.trim();
    var query = _ref.where('hskLevel', isEqualTo: hskLevel);
    if (normalizedTopic.isNotEmpty) {
      query = query.where('topic', isEqualTo: normalizedTopic);
    }
    final result = await query.get();
    return _sortedByStt(result.docs);
  }

  @override
  Future<int> getWordCountByLvl(String hskLevel) async {
    final result = await _ref.where('hskLevel', isEqualTo: hskLevel).get();
    return result.docs.length;
  }

  List<Word> _sortedByStt(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final words = docs.map(_toWord).toList()
      ..sort((a, b) {
        final left = int.tryParse(a.stt) ?? 0;
        final right = int.tryParse(b.stt) ?? 0;
        return left.compareTo(right);
      });
    return words;
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

  String _toString(Object? value) => value?.toString() ?? '';
}
