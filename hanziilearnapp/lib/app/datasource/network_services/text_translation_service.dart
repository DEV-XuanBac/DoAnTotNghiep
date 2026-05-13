import 'dart:math' as math;

import 'package:hanziilearnapp/app/datasource/local/cn_vi_dictionary_db_service.dart';
import 'package:translator/translator.dart';

enum TranslationMode { balanced, strictNatural }

class TextTranslationService {
  TextTranslationService({
    GoogleTranslator? translator,
    CnViDictionaryDbService? dictionaryDbService,
  }) : _translator = translator ?? GoogleTranslator(),
       _dictDb = dictionaryDbService ?? CnViDictionaryDbService();

  final GoogleTranslator _translator;
  final CnViDictionaryDbService _dictDb;

  static final _sentenceMarks = RegExp(
    r'[，,、：:]',
  ); // nhận diện chunk có dấu câu
  static final _chunkSplit = RegExp(
    r'[。！？!?；;\n]+',
  ); // tách đoạn văn thành chunk
  static final _paraSplit = RegExp(r'\n{2,}'); // tách đoạn trong vb đã dịch
  static final _possessiveArtifact = RegExp(
    r'\b(tôi|ta|mình|bạn|anh ấy|cô ấy|nó|họ|chúng tôi|chúng ta)\s+của\b',
  ); // nhận diện các từ chỉ sở hữu
  static final _laOfArtifact = RegExp(
    r'\blà\b[^.!?]{0,24}\bcủa\b',
  ); // nhận diện cấu trúc "là ... của"

  Future<String> trText(
    String text, {
    required String from,
    required String to,
    TranslationMode mode = TranslationMode.balanced,
  }) async {
    final src = text.trim();
    if (src.isEmpty) return '';

    if (from == 'zh-cn' && to == 'vi') {
      final out = <String>[];
      for (final c in _splitChunks(src)) {
        final t = c.trim();
        if (t.isNotEmpty) {
          out.add(await _translateChunk(t, from: from, to: to, mode: mode));
        }
      } // Dịch từng chunk, ghép và làm sạch định dạng
      return _postProcessTranslation(out.join('\n'), targetLanguage: to);
    }

    final mtOut = await _mt(src, from, to);
    return _postProcessTranslation(mtOut, targetLanguage: to);
  }

  Future<String> _translateChunk(
    String chunk, {
    required String from,
    required String to,
    required TranslationMode mode,
  }) async {
    if (mode == TranslationMode.strictNatural) {
      return _mt(chunk, from, to);
    }

    final short = chunk.length <= 6 && !_sentenceMarks.hasMatch(chunk);
    final dict = await _dictDb.lookMeaning(chunk);
    if (dict != null) {
      final d = _pickPrimaryMeaning(dict); //chọn nghĩa chính
      if (!_isLowQualityVi(d)) return d;
    }

    if (short) {
      final sub = await _translateSubPhrases(chunk, from: from, to: to);
      if (sub != null && !_isLowQualityVi(sub)) return sub;
    }

    return _applyDictionaryOverrides(
      sourceChunk: chunk,
      mtText: await _mt(chunk, from, to),
      from: from,
      to: to,
    ); //ghi đè từ điển nếu có
  }

  Future<String> _mt(String text, String from, String to) async {
    return (await _translator.translate(text, from: from, to: to)).text;
  }

  Future<String?> _translateSubPhrases(
    String chunk, {
    required String from,
    required String to,
  }) async {
    final pieces = <String>[];
    final buf = StringBuffer();
    var i = 0;
    var hits = 0;

    Future<void> flush() async {
      if (buf.isEmpty) return;
      pieces.add(await _mt(buf.toString(), from, to));
      buf.clear();
    }

    while (i < chunk.length) {
      final m = await _findLongestMatch(chunk, i);
      if (m != null) {
        await flush();
        pieces.add(m.meaning);
        hits++;
        i = m.end;
      } else {
        buf.write(chunk[i]);
        i++;
      }
    }
    await flush();
    return hits == 0 ? null : pieces.join(' ');
  }

  Future<_ChunkMatch?> _findLongestMatch(
    String chunk,
    int start, {
    int minLen = 1,
  }) async {
    if (start >= chunk.length) return null;
    final maxLen = math.min(18, chunk.length - start);
    for (var len = maxLen; len >= minLen; len--) {
      final cand = chunk.substring(start, start + len).trim();
      if (cand.isEmpty) continue;
      final meaning = await _dictDb.lookMeaning(cand);
      if (meaning != null) {
        return _ChunkMatch(start + len, _pickPrimaryMeaning(meaning));
      }
    }
    return null;
  }

  List<String> _splitChunks(String text) {
    final n = text.replaceAll('\r\n', '\n').trim();
    if (n.isEmpty) return const [];
    final parts = n
        .split(_chunkSplit)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? [n] : parts;
  }

  String _postProcessTranslation(
    String text, {
    required String targetLanguage,
  }) {
    return text
        .replaceAll('\r\n', '\n')
        .trim()
        .split(_paraSplit)
        .map(
          (p) =>
              _normalizeTranslatedParagraph(p, targetLanguage: targetLanguage),
        )
        .where((p) => p.isNotEmpty)
        .join('\n\n')
        .trim();
  }

  String _normalizeTranslatedParagraph(
    String text, {
    required String targetLanguage,
  }) {
    var s = text
        .replaceAll(RegExp(r'\s*\n\s*'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAllMapped(RegExp(r'\s+([,.;:!?])'), (m) => m.group(1) ?? '')
        .replaceAll('( ', '(')
        .replaceAll('[ ', '[')
        .replaceAll('{ ', '{')
        .replaceAll(' )', ')')
        .replaceAll(' ]', ']')
        .replaceAll(' }', '}')
        .trim();
    if (targetLanguage == 'vi') s = _capitalizeFirstLetter(s);
    return s;
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    final i = text.indexOf(RegExp(r'\S'));
    if (i < 0) return text;
    return '${text.substring(0, i)}${text[i].toUpperCase()}${text.substring(i + 1)}';
  }

  String _pickPrimaryMeaning(String meaning) {
    final n = meaning.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (n.isEmpty) return n;
    if (n.contains('thành ngữ') || n.contains('tục ngữ')) return n;
    return n
        .split(RegExp(r'[;/|]'))
        .map((e) => e.trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => n);
  }

  Future<String> _applyDictionaryOverrides({
    required String sourceChunk,
    required String mtText,
    required String from,
    required String to,
  }) async {
    if (_sentenceMarks.hasMatch(sourceChunk) || sourceChunk.length > 24) {
      return mtText;
    }

    final phrases = await _collectOverridePhrases(sourceChunk);
    if (phrases.isEmpty || phrases.length > 2) return mtText;

    var out = mtText;
    for (final p in phrases) {
      if (p.source.length < 2) continue;
      final machine = (await _mt(p.source, from, to)).trim();
      final dict = p.meaning.trim();
      if (machine.length < 3 || dict.isEmpty || machine == dict) continue;
      out = _replaceFirstWholeWord(out, machine, dict);
    }
    return out;
  }

  Future<List<_OverridePhrase>> _collectOverridePhrases(String chunk) async {
    final list = <_OverridePhrase>[];
    var i = 0;
    while (i < chunk.length) {
      final m = await _findLongestMatch(chunk, i, minLen: 2);
      if (m == null) {
        i++;
        continue;
      }
      if (!_isLowQualityVi(m.meaning)) {
        list.add(_OverridePhrase(chunk.substring(i, m.end), m.meaning));
      }
      i = m.end;
    }
    return list;
  }

  String _replaceFirstWholeWord(String text, String from, String to) {
    final pattern = RegExp(
      '(^|\\b)${RegExp.escape(from)}(\\b|\$)',
      caseSensitive: false,
    );
    final m = pattern.firstMatch(text);
    if (m == null) return text;
    final start = m.start + (m.group(1)?.length ?? 0);
    final end = m.end - (m.group(2)?.length ?? 0);
    return '${text.substring(0, start)}$to${text.substring(end)}';
  }

  bool _isLowQualityVi(String text) {
    final n = text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    if (n.isEmpty) return true;
    if (n == 'của' ||
        n.endsWith(' của') ||
        n.endsWith(' và') ||
        n.endsWith(' là')) {
      return true;
    }
    if (_possessiveArtifact.hasMatch(n) || _laOfArtifact.hasMatch(n)) {
      return true;
    }
    if (n.contains(' vợ và con cái') || n.contains(';') || n.contains('/')) {
      return true;
    }
    return false;
  }
}

class _ChunkMatch {
  final int end;
  final String meaning;
  const _ChunkMatch(this.end, this.meaning);
}

class _OverridePhrase {
  final String source;
  final String meaning;
  const _OverridePhrase(this.source, this.meaning);
}
