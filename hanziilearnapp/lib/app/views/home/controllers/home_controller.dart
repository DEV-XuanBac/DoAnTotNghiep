import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hanziilearnapp/app/datasource/local/cn_vi_dictionary_db_service.dart';
import 'package:hanziilearnapp/app/datasource/local/local_pronunciation_service.dart';
import 'package:hanziilearnapp/app/models/lookup_history_item.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends ChangeNotifier {
  static const streakKey = 'home.login.streak';
  static const loginDatesKey = 'home.login.dates';
  static const historyKey = 'home.lookup.history';

  final CnViDictionaryDbService _dictionaryDbService;
  final LocalPronunciationService _speechService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HomeController({
    CnViDictionaryDbService? dictionaryDbService,
    LocalPronunciationService? speechService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _dictionaryDbService = dictionaryDbService ?? CnViDictionaryDbService(),
       _speechService = speechService ?? LocalPronunciationService(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  bool isViMode = true;
  bool searching = false;
  bool listening = false;
  bool handwritingBusy = false;
  bool searchSubmitted = false;

  String? errMsg;
  Word? pickedWord;
  List<Word> sugWords = [];
  List<Word> relWords = [];
  List<LookupHistoryItem> history = [];

  int streak = 1;
  Set<int> checkedDays = {DateTime.now().weekday - 1};

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadLoginStreak(prefs);
    await _loadHistory(prefs);
  }

  Future<void> disposeCtrl() async {
    await _speechService.cancel();
  }

  void clearSearch() {
    sugWords = [];
    pickedWord = null;
    relWords = [];
    errMsg = null;
    searchSubmitted = false;
    notifyListeners();
  }

  void setViMode(bool isVi) {
    isViMode = isVi;
    errMsg = null;
    pickedWord = null;
    relWords = [];
    sugWords = [];
    notifyListeners();
  }

  void markSearchSubmitted() {
    searchSubmitted = true;
    notifyListeners();
  }

  void clearSubmittedFlag() {
    if (!searchSubmitted) {
      return;
    }
    searchSubmitted = false;
    notifyListeners();
  }

  void setErr(String? msg) {
    errMsg = msg;
    notifyListeners();
  }

  Future<void> loadSuggestions(String keyword) async {
    searching = true;
    errMsg = null;
    notifyListeners();
    try {
      final words = await _dictionaryDbService.searchWords(
        keyword: keyword,
        searchByVietnamese: isViMode,
      );
      sugWords = words;
    } catch (_) {
      errMsg = 'Không nhận diện được mặt chữ';
    } finally {
      searching = false;
      notifyListeners();
    }
  }

  Future<bool> submit(String keyword) async {
    if (keyword.isEmpty) {
      errMsg = 'Không nhận diện được mặt chữ';
      searchSubmitted = true;
      notifyListeners();
      return false;
    }

    searchSubmitted = true;
    notifyListeners();

    if (sugWords.isEmpty) {
      await loadSuggestions(keyword);
    }
    if (sugWords.isEmpty) {
      errMsg = 'Không nhận diện được mặt chữ';
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> pickWord(
    Word word, {
    required bool saveToHistory,
    required String query,
  }) async {
    pickedWord = word;
    errMsg = null;
    notifyListeners();

    final related = await _dictionaryDbService.getRelatedWords(word);
    relWords = related;
    notifyListeners();

    if (!saveToHistory) {
      return;
    }

    final item = LookupHistoryItem(
      word: word,
      searchedAt: DateTime.now(),
      searchMode: isViMode ? 'vietnamese' : 'hanzi',
      query: query,
    );

    history.removeWhere((h) => h.word.id == item.word.id);
    history.insert(0, item);
    if (history.length > 100) {
      history = history.sublist(0, 100);
    }
    await _persistHistory();
    notifyListeners();
  }

  Future<void> toggleMic({
    required void Function(String text) onRecognizedText,
  }) async {
    if (listening) {
      await _speechService.stopListening();
      listening = false;
      notifyListeners();
      return;
    }

    try {
      listening = true;
      errMsg = null;
      notifyListeners();

      await _speechService.startListen(
        localeId: isViMode ? 'vi-VN' : 'zh-CN',
        onPartialResult: (text) {
          final value = text.trim();
          if (value.isEmpty) return;
          onRecognizedText(value);
        },
      );
    } catch (_) {
      listening = false;
      errMsg = 'Không nhận diện được mặt chữ';
      notifyListeners();
    }
  }

  Future<void> setHandwritingBusy(bool value) async {
    handwritingBusy = value;
    notifyListeners();
  }

  Future<void> _loadLoginStreak(SharedPreferences prefs) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final storedDates = prefs.getStringList(loginDatesKey) ?? [];

    final parsedDates =
        storedDates
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .map((date) => DateTime(date.year, date.month, date.day))
            .toList()
          ..sort();

    final hasToday = parsedDates.any((date) => date == today);
    final previousDate = parsedDates.isEmpty ? null : parsedDates.last;

    var streak = prefs.getInt(streakKey) ?? 0;
    if (!hasToday) {
      if (previousDate == null) {
        streak = 1;
      } else {
        final diff = today.difference(previousDate).inDays;
        streak = diff == 1 ? streak + 1 : 1;
      }
      parsedDates.add(today);
    }

    final latestDates = parsedDates.length > 60
        ? parsedDates.sublist(parsedDates.length - 60)
        : parsedDates;

    final thisWeekMonday = today.subtract(Duration(days: today.weekday - 1));
    final checkedIndexes = latestDates
        .where((date) => !date.isBefore(thisWeekMonday) && !date.isAfter(today))
        .map((date) => date.weekday - 1)
        .toSet();

    await prefs.setInt(streakKey, streak);
    await prefs.setStringList(
      loginDatesKey,
      latestDates.map((date) => date.toIso8601String()).toList(),
    );

    this.streak = streak;
    checkedDays = checkedIndexes;
    notifyListeners();

    await _syncLoginDateToFirestore(today);
  }

  Future<void> _syncLoginDateToFirestore(DateTime today) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final key =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await _firestore.collection('users').doc(user.uid).set({
      'login_dates': FieldValue.arrayUnion([key]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _loadHistory(SharedPreferences prefs) async {
    final raw = prefs.getString(historyKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      final items =
          decoded
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (item) =>
                    LookupHistoryItem.fromJson(item.cast<String, dynamic>()),
              )
              .toList()
            ..sort((a, b) => b.searchedAt.compareTo(a.searchedAt));

      history = items;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = history.map((item) => item.toJson()).toList();
    await prefs.setString(historyKey, jsonEncode(payload));
  }
}
