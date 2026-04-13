import 'package:flutter/widgets.dart';
import 'package:hanziilearnapp/app/datasource/network_services/dictionary_service.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

class LessonProvider extends ChangeNotifier {
  final _service = DictionaryService();

  bool loading = false;
  String? errorMessage;
  String currentLevel = '';
  List<Word> words = [];
  final Set<String> _bookmarkedIds = {};
  bool loadingLevelCounts = false;
  final Map<String, int> levelWordCounts = {};

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

  bool isBookmarked(String wordId) {
    return _bookmarkedIds.contains(wordId);
  }

  void toggleBookmark(String wordId) {
    if (_bookmarkedIds.contains(wordId)) {
      _bookmarkedIds.remove(wordId);
    } else {
      _bookmarkedIds.add(wordId);
    }
    notifyListeners();
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
}
