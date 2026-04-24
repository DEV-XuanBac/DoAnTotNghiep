import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanziilearnapp/app/datasource/network_services/dictionary_service.dart';
import 'package:hanziilearnapp/app/datasource/network_services/hsk_exam_service.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

class NotebookWordItem {
  NotebookWordItem({
    required this.word,
    required this.isFavorite,
    required this.note,
  });

  final Word word;
  final bool isFavorite;
  final String note;
}

class LessonProvider extends ChangeNotifier {
  final _service = DictionaryService();
  final _examService = HskExamService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool loading = false;
  String? errorMessage;
  String currentLevel = '';
  String currentTopic = '';
  List<Word> words = [];
  List<String> topics = [];
  final Set<String> _bookmarkedIds = {};
  int notebookSavedCount = 0;
  int notebookFavoriteCount = 0;
  List<NotebookWordItem> notebookItems = [];
  bool reviewCompleted = false;
  Map<String, dynamic>? reviewResult;
  final Map<String, double> topicCompletionPercent = {};
  bool loadingLevelCounts = false;
  final Map<String, int> levelWordCounts = {};
  bool loadingExamCounts = false;
  final Map<String, int> levelExamCounts = {};

  Future<void> loadWordsByHskLevel(String level) async {
    loading = true;
    errorMessage = null;
    currentLevel = level;
    notifyListeners();

    try {
      words = await _service.getWordsByHskLevel(level);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadTopicsByHskLevel(String level) async {
    loading = true;
    errorMessage = null;
    currentLevel = level;
    currentTopic = '';
    words = [];
    topics = [];
    notifyListeners();

    try {
      topics = await _service.getTopicsByHskLevel(level);
      await _loadTopicCompletionByLevel(level);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadWordsByTopic({
    required String level,
    required String topic,
  }) async {
    loading = true;
    errorMessage = null;
    currentLevel = level;
    currentTopic = topic;
    words = [];
    notifyListeners();

    try {
      words = await _service.getWordsByHskLevelAndTopic(level, topic);
      await _syncBookmarksForCurrentUser();
      await _loadReviewResult(level: level, topic: topic);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  bool isBookmarked(String wordId) {
    return _bookmarkedIds.contains(wordId);
  }

  Future<void> toggleBookmark(Word word) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Vui lòng đăng nhập để lưu từ vào sổ tay.');
    }

    final docId = '${user.uid}_${word.id}';
    final notebookRef = _firestore.collection('soTayTuVung').doc(docId);
    final existed = _bookmarkedIds.contains(word.id);

    if (existed) {
      _bookmarkedIds.remove(word.id);
      notifyListeners();
      await notebookRef.delete();
      await loadNotebookStats();
      return;
    }

    _bookmarkedIds.add(word.id);
    notifyListeners();
    await notebookRef.set({
      'wordId': word.id,
      'userId': user.uid,
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
    await loadNotebookStats();
  }

  Future<void> loadNotebookStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      notebookSavedCount = 0;
      notebookFavoriteCount = 0;
      notifyListeners();
      return;
    }
    final result = await _firestore
        .collection('soTayTuVung')
        .where('userId', isEqualTo: user.uid)
        .get();

    notebookSavedCount = result.docs.length;
    notebookFavoriteCount = result.docs
        .where((doc) => doc.data()['isFavorite'] == true)
        .length;
    notifyListeners();
  }

  Future<void> loadNotebookWords() async {
    final user = _auth.currentUser;
    notebookItems = [];
    if (user == null) {
      notifyListeners();
      return;
    }
    final result = await _firestore
        .collection('soTayTuVung')
        .where('userId', isEqualTo: user.uid)
        .get();

    notebookItems = result.docs.map((doc) {
      final data = doc.data();
      final word = Word(
        id: data['wordId']?.toString() ?? '',
        hanzi: data['hanzi']?.toString() ?? '',
        pinyin: data['pinyin']?.toString() ?? '',
        meaning: data['meaning']?.toString() ?? '',
        hskLevel: data['hskLevel']?.toString() ?? '',
        topic: data['topic']?.toString() ?? '',
        ttsUrl: data['ttsUrl']?.toString() ?? '',
      );
      return NotebookWordItem(
        word: word,
        isFavorite: data['isFavorite'] == true,
        note: data['note']?.toString() ?? '',
      );
    }).toList();
    notebookItems.sort((a, b) => a.word.hanzi.compareTo(b.word.hanzi));
    notifyListeners();
  }

  Future<void> toggleFavoriteInNotebook(String wordId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docRef = _firestore.collection('soTayTuVung').doc('${user.uid}_$wordId');
    final doc = await docRef.get();
    final current = doc.data()?['isFavorite'] == true;
    await docRef.set({'isFavorite': !current}, SetOptions(merge: true));
    await loadNotebookWords();
    await loadNotebookStats();
  }

  Future<void> updateNotebookNote(String wordId, String note) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docRef = _firestore.collection('soTayTuVung').doc('${user.uid}_$wordId');
    await docRef.set({'note': note.trim()}, SetOptions(merge: true));
    await loadNotebookWords();
  }

  Future<void> loadHskLevelCounts(List<String> levels) async {
    loadingLevelCounts = true;
    notifyListeners();

    try {
      final results = await Future.wait(
        levels.map((level) async {
          final count = await _service.getWordCountByHskLevel(level);
          return MapEntry(level, count);
        }),
      );

      final nextCounts = <String, int>{
        for (final entry in results) entry.key: entry.value,
      };
      levelWordCounts
        ..clear()
        ..addAll(nextCounts);
    } finally {
      loadingLevelCounts = false;
      notifyListeners();
    }
  }

  Future<void> loadHskExamCounts(List<String> levels) async {
    loadingExamCounts = true;
    notifyListeners();

    try {
      final results = await Future.wait(
        levels.map((level) async {
          final exams = await _examService.getExamsByLevel(level);
          return MapEntry(level, exams.length);
        }),
      );

      final nextCounts = <String, int>{
        for (final entry in results) entry.key: entry.value,
      };
      levelExamCounts
        ..clear()
        ..addAll(nextCounts);
    } finally {
      loadingExamCounts = false;
      notifyListeners();
    }
  }

  Future<void> _syncBookmarksForCurrentUser() async {
    final user = _auth.currentUser;
    _bookmarkedIds.clear();
    if (user == null || words.isEmpty) {
      return;
    }

    final wordIds = words.map((word) => word.id).toSet();
    final result = await _firestore
        .collection('soTayTuVung')
        .where('userId', isEqualTo: user.uid)
        .get();

    for (final doc in result.docs) {
      final savedWordId = doc.data()['wordId']?.toString() ?? '';
      if (wordIds.contains(savedWordId)) {
        _bookmarkedIds.add(savedWordId);
      }
    }
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

    final docRef = _firestore
        .collection('soTayOnTap')
        .doc('${user.uid}_${_slug(level)}_${_slug(topic)}');
    final existed = await docRef.get();
    if (existed.exists && (existed.data()?['completed'] == true)) {
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

    await docRef.set(payload, SetOptions(merge: true));
    reviewCompleted = true;
    reviewResult = payload;
    topicCompletionPercent[topic] = completionPercent;
    notifyListeners();
  }

  Future<void> _loadReviewResult({
    required String level,
    required String topic,
  }) async {
    final user = _auth.currentUser;
    reviewCompleted = false;
    reviewResult = null;
    if (user == null) {
      return;
    }

    final doc = await _firestore
        .collection('soTayOnTap')
        .doc('${user.uid}_${_slug(level)}_${_slug(topic)}')
        .get();

    if (!doc.exists) {
      return;
    }

    final data = doc.data() ?? <String, dynamic>{};
    reviewCompleted = data['completed'] == true;
    reviewResult = data;
    if (reviewCompleted) {
      final percent = (data['completionPercent'] as num?)?.toDouble() ??
          _computePercentFromData(data);
      topicCompletionPercent[topic] = percent;
    }
  }

  Future<void> _loadTopicCompletionByLevel(String level) async {
    final user = _auth.currentUser;
    topicCompletionPercent.clear();
    if (user == null) {
      return;
    }

    final result = await _firestore
        .collection('soTayOnTap')
        .where('userId', isEqualTo: user.uid)
        .where('hskLevel', isEqualTo: level)
        .where('completed', isEqualTo: true)
        .get();

    for (final doc in result.docs) {
      final data = doc.data();
      final topic = data['topic']?.toString().trim() ?? '';
      if (topic.isEmpty) {
        continue;
      }
      final percent = (data['completionPercent'] as num?)?.toDouble() ??
          _computePercentFromData(data);
      topicCompletionPercent[topic] = percent;
    }
  }

  bool isTopicCompleted(String topic) {
    final value = topicCompletionPercent[topic];
    return value != null;
  }

  double getTopicCompletionPercent(String topic) {
    return topicCompletionPercent[topic] ?? 0.0;
  }

  double _computePercentFromData(Map<String, dynamic> data) {
    final total = (data['totalQuestions'] as num?)?.toDouble() ?? 0;
    final correct = (data['correctAnswers'] as num?)?.toDouble() ?? 0;
    if (total <= 0) {
      return 0;
    }
    return (correct / total) * 100;
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\u00C0-\u1EF9\u4e00-\u9fff]'), '');
  }
}
