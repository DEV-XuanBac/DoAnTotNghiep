import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

/// Chuẩn hóa và so sánh đáp án theo từng [HskExamQuestion.questionType].
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

  static bool hasAnswer(HskExamQuestion question, String? selected) {
    if (selected == null) {
      return false;
    }
    return selected.trim().isNotEmpty;
  }
}
