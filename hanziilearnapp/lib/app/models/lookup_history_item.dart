import 'package:hanziilearnapp/app/models/word_model.dart';

class LookupHistoryItem {
  const LookupHistoryItem({
    required this.word,
    required this.searchedAt,
    required this.searchMode,
    required this.query,
  });

  final Word word;
  final DateTime searchedAt;
  final String searchMode; // hanzi | vietnamese
  final String query;

  Map<String, dynamic> toJson() {
    return {
      'searchedAt': searchedAt.toIso8601String(),
      'searchMode': searchMode,
      'query': query,
      'word': {
        'id': word.id,
        'hanzi': word.hanzi,
        'pinyin': word.pinyin,
        'meaning': word.meaning,
        'hskLevel': word.hskLevel,
        'stt': word.stt,
        'topic': word.topic,
        'ttsUrl': word.ttsUrl,
        'exampleHanzi': word.exampleHanzi,
        'examplePinyin': word.examplePinyin,
        'exampleMeaning': word.exampleMeaning,
      },
    };
  }

  factory LookupHistoryItem.fromJson(Map<String, dynamic> json) {
    final rawWord = (json['word'] as Map?)?.cast<String, dynamic>() ?? {};
    return LookupHistoryItem(
      searchedAt:
          DateTime.tryParse((json['searchedAt'] ?? '').toString()) ??
          DateTime.now(),
      searchMode: (json['searchMode'] ?? 'vietnamese').toString(),
      query: (json['query'] ?? '').toString(),
      word: Word(
        id: (rawWord['id'] ?? '').toString(),
        hanzi: (rawWord['hanzi'] ?? '').toString(),
        pinyin: (rawWord['pinyin'] ?? '').toString(),
        meaning: (rawWord['meaning'] ?? '').toString(),
        hskLevel: (rawWord['hskLevel'] ?? '').toString(),
        stt: (rawWord['stt'] ?? '').toString(),
        topic: (rawWord['topic'] ?? '').toString(),
        ttsUrl: (rawWord['ttsUrl'] ?? '').toString(),
        exampleHanzi: (rawWord['exampleHanzi'] ?? '').toString(),
        examplePinyin: (rawWord['examplePinyin'] ?? '').toString(),
        exampleMeaning: (rawWord['exampleMeaning'] ?? '').toString(),
      ),
    );
  }
}
