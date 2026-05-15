import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

class HskExamAnswerUtils {
  HskExamAnswerUtils._();

  static bool isAnswerCorrect(HskExamQuestion question, String? selected) {
    if (selected == null) {
      return false;
    }
    final trimmed = selected.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    switch (question.questionType) {
      case 'write_sentence':
        return _writeOk(question, trimmed);
      case 'sort_word':
        return normalizeWrittenChinese(trimmed) ==
            normalizeWrittenChinese(question.correctAnswer.trim());
      case 'sort_sentences':
        return normalizeSortSentenceKey(trimmed) ==
            normalizeSortSentenceKey(question.correctAnswer.trim());
      default:
        return trimmed.toLowerCase() == question.correctAnswer.trim().toLowerCase();
    }
  }

  /// Bỏ khoảng trắng, bỏ dấu câu cuối (。！？) để chấm câu sắp từ / viết câu.
  static String normalizeWrittenChinese(String input) {
    final stripped = input.replaceAll(RegExp(r'\s+'), '');
    return _stripTrailingCnPunctuation(stripped);
  }

  static String normalizeSortSentenceKey(String input) {
    return input.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  static String _stripTrailingCnPunctuation(String s) {
    var t = s;
    const punct = '。.！!？?';
    while (t.isNotEmpty && punct.contains(t[t.length - 1])) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }

  static const double writeSimMin = 0.7;

  static bool _writeOk(HskExamQuestion q, String t) {
    final un = normalizeWrittenChinese(t);
    final kn = normalizeWrittenChinese(q.correctAnswer.trim());
    if (un.isEmpty || kn.isEmpty) {
      return false;
    }
    final reqs = _reqParts(q.questionText);
    if (reqs.isEmpty) {
      return un == kn;
    }
    for (final fr in reqs) {
      final fn = normalizeWrittenChinese(fr);
      if (fn.isEmpty) {
        continue;
      }
      if (!un.contains(fn)) {
        return false;
      }
    }
    return _levSim(un, kn) >= writeSimMin;
  }

  static List<String> _reqParts(String qt) {
    final s = qt.trim();
    if (s.isEmpty) {
      return const <String>[];
    }
    const pat = r'[\s、，,;；|/]+';
    final ps = s
        .split(RegExp(pat))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return ps.isEmpty ? <String>[s] : ps;
  }

  static double _levSim(String a, String b) {
    final na = a.runes.length;
    final nb = b.runes.length;
    if (na == 0 && nb == 0) {
      return 1;
    }
    if (na == 0 || nb == 0) {
      return 0;
    }
    final mx = na > nb ? na : nb;
    final d = _lev(a, b);
    return 1.0 - d / mx;
  }

  static int _lev(String a, String b) {
    final ra = a.runes.toList();
    final rb = b.runes.toList();
    final n = ra.length;
    final m = rb.length;
    var p = List<int>.generate(m + 1, (j) => j);
    var c = List<int>.filled(m + 1, 0);
    for (var i = 1; i <= n; i++) {
      c[0] = i;
      final ai = ra[i - 1];
      for (var j = 1; j <= m; j++) {
        final co = ai == rb[j - 1] ? 0 : 1;
        final del = p[j] + 1;
        final ins = c[j - 1] + 1;
        final sub = p[j - 1] + co;
        final mv = del < ins ? del : ins;
        c[j] = mv < sub ? mv : sub;
      }
      final sw = p;
      p = c;
      c = sw;
    }
    return p[m];
  }

  static bool hasAnswer(HskExamQuestion question, String? selected) {
    if (selected == null) {
      return false;
    }
    return selected.trim().isNotEmpty;
  }
}
