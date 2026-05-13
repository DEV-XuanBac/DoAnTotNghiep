import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanziilearnapp/app/models/notebook_word_item.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

/// Truy cập collection `soTayTuVung`.
abstract class INotebookRepository {
  Future<Set<String>> savedWordIdsForUserIntersecting({
    required String userId,
    required Set<String> wordIds,
  });

  Future<void> deleteEntry(String docId);

  Future<void> upsertWordEntry({
    required String docId,
    required String userId,
    required Word word,
  });

  Future<({int saved, int favorites})> statsForUser(String userId);

  Future<List<NotebookWordItem>> listItemsForUser(String userId);

  Future<bool> readIsFavorite({required String userId, required String wordId});

  Future<void> mergeFields({
    required String userId,
    required String wordId,
    required Map<String, dynamic> fields,
  });
}

class NotebookRepository implements INotebookRepository {
  NotebookRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collection = 'soTayTuVung';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  @override
  Future<Set<String>> savedWordIdsForUserIntersecting({
    required String userId,
    required Set<String> wordIds,
  }) async {
    if (wordIds.isEmpty) {
      return <String>{};
    }
    final result = await _ref.where('userId', isEqualTo: userId).get();
    final out = <String>{};
    for (final doc in result.docs) {
      final savedWordId = (doc.data()['wordId'] ?? '').toString();
      if (wordIds.contains(savedWordId)) {
        out.add(savedWordId);
      }
    }
    return out;
  }

  @override
  Future<void> deleteEntry(String docId) => _ref.doc(docId).delete();

  @override
  Future<void> upsertWordEntry({
    required String docId,
    required String userId,
    required Word word,
  }) {
    return _ref.doc(docId).set(<String, dynamic>{
      'wordId': word.id,
      'userId': userId,
      'hanzi': word.hanzi,
      'pinyin': word.pinyin,
      'meaning': word.meaning,
      'hskLevel': word.hskLevel,
      'topic': word.topic,
      'exampleHanzi': word.exampleHanzi,
      'examplePinyin': word.examplePinyin,
      'exampleMeaning': word.exampleMeaning,
      'ttsUrl': word.ttsUrl,
      'isFavorite': false,
      'note': '',
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<({int saved, int favorites})> statsForUser(String userId) async {
    final result = await _ref.where('userId', isEqualTo: userId).get();
    final favorites = result.docs
        .where((doc) => doc.data()['isFavorite'] == true)
        .length;
    return (saved: result.docs.length, favorites: favorites);
  }

  @override
  Future<List<NotebookWordItem>> listItemsForUser(String userId) async {
    final result = await _ref.where('userId', isEqualTo: userId).get();
    final items = result.docs.map((doc) {
      final data = doc.data();
      final word = Word(
        id: (data['wordId'] ?? '').toString(),
        hanzi: (data['hanzi'] ?? '').toString(),
        pinyin: (data['pinyin'] ?? '').toString(),
        meaning: (data['meaning'] ?? '').toString(),
        hskLevel: (data['hskLevel'] ?? '').toString(),
        topic: (data['topic'] ?? '').toString(),
        ttsUrl: (data['ttsUrl'] ?? '').toString(),
      );
      return NotebookWordItem(
        word: word,
        isFavorite: data['isFavorite'] == true,
        note: (data['note'] ?? '').toString(),
      );
    }).toList()..sort((a, b) => a.word.hanzi.compareTo(b.word.hanzi));
    return items;
  }

  @override
  Future<bool> readIsFavorite({
    required String userId,
    required String wordId,
  }) async {
    final doc = await _ref.doc('${userId}_$wordId').get();
    return doc.data()?['isFavorite'] == true;
  }

  @override
  Future<void> mergeFields({
    required String userId,
    required String wordId,
    required Map<String, dynamic> fields,
  }) {
    return _ref.doc('${userId}_$wordId').set(fields, SetOptions(merge: true));
  }
}
