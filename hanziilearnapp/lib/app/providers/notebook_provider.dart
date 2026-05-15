import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hanziilearnapp/app/datasource/repository/notebook_repository.dart';
import 'package:hanziilearnapp/app/models/notebook_word_item.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

export 'package:hanziilearnapp/app/models/notebook_word_item.dart';

class NotebookProvider extends ChangeNotifier {
  NotebookProvider({FirebaseAuth? auth, INotebookRepository? repository})
    : _auth = auth ?? FirebaseAuth.instance,
      _repo = repository ?? NotebookRepository();

  final FirebaseAuth _auth;
  final INotebookRepository _repo;

  final Set<String> _bookmarkedIds = <String>{};
  int notebookSavedCount = 0;
  int notebookFavoriteCount = 0;
  List<NotebookWordItem> notebookItems = const <NotebookWordItem>[];

  bool isBookmarked(String wordId) => _bookmarkedIds.contains(wordId);

  Future<void> syncBookmarksForWords(List<Word> words) async {
    final user = _auth.currentUser;
    _bookmarkedIds.clear();
    if (user == null || words.isEmpty) {
      notifyListeners();
      return;
    }

    final wordIds = words.map((word) => word.id).toSet();
    final saved = await _repo.savedWordIdsForUserIntersecting(
      userId: user.uid,
      wordIds: wordIds,
    );
    _bookmarkedIds.addAll(saved);
    notifyListeners();
  }

  Future<void> toggleBookmark(Word word) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Vui lòng đăng nhập để lưu từ vào sổ tay.');
    }

    final docId = '${user.uid}_${word.id}';
    final existed = _bookmarkedIds.contains(word.id);

    if (existed) {
      _bookmarkedIds.remove(word.id);
      notifyListeners();
      await _repo.deleteEntry(docId);
      await loadNotebookStats();
      return;
    }

    _bookmarkedIds.add(word.id);
    notifyListeners();
    await _repo.upsertWordEntry(docId: docId, userId: user.uid, word: word);
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
    final stats = await _repo.statsForUser(user.uid);
    notebookSavedCount = stats.saved;
    notebookFavoriteCount = stats.favorites;
    notifyListeners();
  }

  Future<void> loadNotebookWords() async {
    final user = _auth.currentUser;
    notebookItems = const <NotebookWordItem>[];
    if (user == null) {
      notifyListeners();
      return;
    }
    notebookItems = await _repo.listItemsForUser(user.uid);
    notifyListeners();
  }

  Future<void> toggleFavoriteInNotebook(String wordId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final current = await _repo.readIsFavorite(
      userId: user.uid,
      wordId: wordId,
    );
    await _repo.mergeFields(
      userId: user.uid,
      wordId: wordId,
      fields: <String, dynamic>{'isFavorite': !current},
    );
    await loadNotebookWords();
    await loadNotebookStats();
  }

  Future<void> updateNotebookNote(String wordId, String note) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await _repo.mergeFields(
      userId: user.uid,
      wordId: wordId,
      fields: <String, dynamic>{'note': note.trim()},
    );
    await loadNotebookWords();
  }
}
