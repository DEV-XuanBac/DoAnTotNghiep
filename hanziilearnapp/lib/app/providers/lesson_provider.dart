import 'package:flutter/foundation.dart';
import 'package:hanziilearnapp/app/datasource/repository/dictionary_repository.dart';
import 'package:hanziilearnapp/app/datasource/repository/hsk_exam_repository.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

/// Provider phụ trách "bài học" (HSK level → topics → words) cùng count
/// tổng/số đề. Notebook & Review đã tách sang `NotebookProvider` /
/// `ReviewProvider`.
class LessonProvider extends ChangeNotifier {
  LessonProvider({
    IDictionaryRepository? dictionaryRepository,
    IHskExamRepository? examRepository,
  }) : _dict = dictionaryRepository ?? DictionaryRepository(),
       _examRepo = examRepository ?? HskExamRepository();

  final IDictionaryRepository _dict;
  final IHskExamRepository _examRepo;

  bool loading = false;
  String? errorMessage;
  String currentLevel = '';
  String currentTopic = '';
  List<Word> words = const <Word>[];
  List<String> topics = const <String>[];

  bool loadingLevelCounts = false;
  final Map<String, int> levelWordCounts = <String, int>{};
  bool loadingExamCounts = false;
  final Map<String, int> levelExamCounts = <String, int>{};

  Future<void> loadWordsByHskLevel(String level) async {
    loading = true;
    errorMessage = null;
    currentLevel = level;
    notifyListeners();

    try {
      words = await _dict.getWordsByHskLevel(level);
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
    words = const <Word>[];
    topics = const <String>[];
    notifyListeners();

    try {
      topics = await _dict.getTopicsByHskLevel(level);
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
    words = const <Word>[];
    notifyListeners();

    try {
      words = await _dict.getWordsByHskLevelAndTopic(level, topic);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void returnToTopicSelection() {
    currentTopic = '';
    words = const <Word>[];
    errorMessage = null;
    notifyListeners();
  }

  Future<void> loadHskLevelCounts(List<String> levels) async {
    loadingLevelCounts = true;
    notifyListeners();

    try {
      final results = await Future.wait<MapEntry<String, int>>(
        levels.map((level) async {
          final count = await _dict.getWordCountByLvl(level);
          return MapEntry(level, count);
        }),
      );

      levelWordCounts
        ..clear()
        ..addEntries(results);
    } finally {
      loadingLevelCounts = false;
      notifyListeners();
    }
  }

  Future<void> loadHskExamCounts(List<String> levels) async {
    loadingExamCounts = true;
    notifyListeners();

    try {
      final results = await Future.wait<MapEntry<String, int>>(
        levels.map((level) async {
          final exams = await _examRepo.getExamsByLevel(level);
          return MapEntry(level, exams.length);
        }),
      );

      levelExamCounts
        ..clear()
        ..addEntries(results);
    } finally {
      loadingExamCounts = false;
      notifyListeners();
    }
  }
}
