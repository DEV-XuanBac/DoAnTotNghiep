import 'package:flutter_test/flutter_test.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';
import 'package:hanziilearnapp/app/utils/hsk_exam_answer_utils.dart';

HskExamQuestion _q({
  required String questionType,
  required String correctAnswer,
  String qt = '',
}) {
  return HskExamQuestion(
    questionId: 1,
    code: 'T1',
    questionType: questionType,
    questionText: qt,
    options: const <String>[],
    correctAnswer: correctAnswer,
  );
}

void main() {
  group('HskExamAnswerUtils.normalizeWrittenChinese', () {
    test('removes spaces', () {
      expect(
        HskExamAnswerUtils.normalizeWrittenChinese('a  b\tc'),
        'abc',
      );
    });

    test('strips trailing Chinese punctuation', () {
      expect(
        HskExamAnswerUtils.normalizeWrittenChinese('你好。'),
        '你好',
      );
      expect(
        HskExamAnswerUtils.normalizeWrittenChinese('答！'),
        '答',
      );
    });
  });

  group('HskExamAnswerUtils.normalizeSortSentenceKey', () {
    test('removes spaces and uppercases', () {
      expect(
        HskExamAnswerUtils.normalizeSortSentenceKey('a b c'),
        'ABC',
      );
    });
  });

  group('HskExamAnswerUtils.isAnswerCorrect', () {
    test('returns false for null or empty', () {
      final q = _q(questionType: 'mcq', correctAnswer: 'A');
      expect(HskExamAnswerUtils.isAnswerCorrect(q, null), false);
      expect(HskExamAnswerUtils.isAnswerCorrect(q, '   '), false);
    });

    test('default type compares case-insensitively', () {
      final q = _q(questionType: 'mcq', correctAnswer: 'AbC');
      expect(HskExamAnswerUtils.isAnswerCorrect(q, 'abc'), true);
      expect(HskExamAnswerUtils.isAnswerCorrect(q, 'ab'), false);
    });

    test('write_sentence uses normalizeWrittenChinese when questionText empty', () {
      final q = _q(questionType: 'write_sentence', correctAnswer: '你好。');
      expect(HskExamAnswerUtils.isAnswerCorrect(q, ' 你好 '), true);
    });

    test('write_sentence requires keywords and fuzzy match to sample answer', () {
      final q = _q(
        questionType: 'write_sentence',
        qt: '风景',
        correctAnswer: '这儿的风景真漂亮。',
      );
      expect(
        HskExamAnswerUtils.isAnswerCorrect(q, '这儿的风景真的很漂亮。'),
        true,
      );
      expect(HskExamAnswerUtils.isAnswerCorrect(q, '天气很好。'), false);
      expect(HskExamAnswerUtils.isAnswerCorrect(q, '答案'), false);
    });

    test('write_sentence fails when keyword missing even if similar', () {
      final q = _q(
        questionType: 'write_sentence',
        qt: '试',
        correctAnswer: '你要不要试试这条裙子？',
      );
      expect(HskExamAnswerUtils.isAnswerCorrect(q, '你要不要买买这条裙子？'), false);
    });

    test('sort_word uses normalizeWrittenChinese', () {
      final q = _q(questionType: 'sort_word', correctAnswer: '学习');
      expect(HskExamAnswerUtils.isAnswerCorrect(q, ' 学 习 '), true);
    });

    test('sort_sentences uses normalizeSortSentenceKey', () {
      final q = _q(questionType: 'sort_sentences', correctAnswer: 'A B');
      expect(HskExamAnswerUtils.isAnswerCorrect(q, 'a  b'), true);
    });
  });

  group('HskExamAnswerUtils.hasAnswer', () {
    test('detects non-empty trimmed selection', () {
      final q = _q(questionType: 'mcq', correctAnswer: 'x');
      expect(HskExamAnswerUtils.hasAnswer(q, null), false);
      expect(HskExamAnswerUtils.hasAnswer(q, ''), false);
      expect(HskExamAnswerUtils.hasAnswer(q, '  '), false);
      expect(HskExamAnswerUtils.hasAnswer(q, ' ok '), true);
    });
  });
}
