import 'dart:convert';

import 'package:hanziilearnapp/app/models/parsed_hsk_exam_model.dart';

abstract class IHskExamValidator {
  ParsedHskExam parseValid(String rawJson);
}

class HskExamValidator implements IHskExamValidator {
  static const Set<String> _baseQuestionTypes = {
    'true_false',
    'single_choice',
  };

  /// Chỉ dùng cho đề HSK4 trở lên (cùng form mở rộng: sắp câu / sắp từ / viết câu).
  static const Set<String> _extendedFormQuestionTypes = {
    'sort_sentences',
    'sort_word',
    'write_sentence',
  };

  @override
  ParsedHskExam parseValid(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON đề thi phải là object ở root.');
    }

    final schemaVersion = decoded['schema_version'];
    if (schemaVersion is! num) {
      throw const FormatException('Thiếu hoặc sai kiểu trường "schema_version".');
    }

    final examCode = _readRequiredText(decoded['exam_code'], 'exam_code');
    final level = _readRequiredText(decoded['level'], 'level');
    final title = _readRequiredText(decoded['title'], 'title');
    final timeLimitMinutes = decoded['time_limit_minutes'];
    if (timeLimitMinutes is! num) {
      throw const FormatException(
        'Thiếu hoặc sai kiểu trường "time_limit_minutes".',
      );
    }
    final audioListening = _readRequiredText(
      decoded['audio_listening'],
      'audio_listening',
    );

    final sectionsRaw = decoded['sections'];
    if (sectionsRaw is! List) {
      throw const FormatException('Trường "sections" phải là danh sách.');
    }
    if (sectionsRaw.isEmpty) {
      throw const FormatException('Danh sách "sections" không được rỗng.');
    }

    final sections = <Map<String, dynamic>>[];
    var questionCount = 0;

    for (var sectionIndex = 0; sectionIndex < sectionsRaw.length; sectionIndex++) {
      final section = sectionsRaw[sectionIndex];
      if (section is! Map<String, dynamic>) {
        throw FormatException(
          'Section thứ ${sectionIndex + 1} không đúng định dạng object.',
        );
      }

      final partId = _readRequiredText(section['part_id'], 'sections.part_id');
      final sectionTitle = _readRequiredText(
        section['section_title'],
        'sections.section_title',
      );
      final skill = _readRequiredText(section['skill'], 'sections.skill');
      final partOrder = section['part_order'];
      if (partOrder is! num) {
        throw FormatException(
          'Section "$partId" thiếu hoặc sai kiểu trường "part_order".',
        );
      }
      final questionCountField = section['question_count'];
      if (questionCountField is! num) {
        throw FormatException(
          'Section "$partId" thiếu hoặc sai kiểu trường "question_count".',
        );
      }
      final questionsRaw = section['questions'];
      if (questionsRaw is! List || questionsRaw.isEmpty) {
        throw FormatException(
          'Section "$partId" phải có danh sách questions không rỗng.',
        );
      }

      final questions = <Map<String, dynamic>>[];
      for (var questionIndex = 0; questionIndex < questionsRaw.length; questionIndex++) {
        final question = questionsRaw[questionIndex];
        if (question is! Map<String, dynamic>) {
          throw FormatException(
            'Question thứ ${questionIndex + 1} của section "$partId" phải là object.',
          );
        }
        final questionId = question['question_id'];
        if (questionId is! num) {
          throw FormatException(
            'question_id ở section "$partId" câu ${questionIndex + 1} phải là số.',
          );
        }
        final code = _readRequiredText(question['code'], 'questions.code');
        final questionType = _readRequiredText(
          question['question_type'],
          'questions.question_type',
        );
        final questionText = (question['question_text'] ?? '').toString().trim();
        final optionsRaw = question['options'];
        if (optionsRaw is! List) {
          throw FormatException(
            'Question "$code" của section "$partId" phải có trường options là danh sách.',
          );
        }
        final options = optionsRaw.map((option) => option.toString().trim()).toList();
        _assertAllowedQuestionType(
          questionType: questionType,
          level: level,
          code: code,
          partId: partId,
        );
        final correctAnswer = _readRequiredText(
          question['correct_answer'],
          'questions.correct_answer',
        );
        _validateQuestionPayload(
          questionType: questionType,
          code: code,
          partId: partId,
          questionText: questionText,
          options: options,
          correctAnswer: correctAnswer,
        );

        questions.add({
          'question_id': questionId.toInt(),
          'code': code,
          'question_type': questionType,
          'question_text': questionText,
          'options': options,
          'correct_answer': correctAnswer,
        });
      }

      questionCount += questions.length;
      if (questionCountField.toInt() != questions.length) {
        throw FormatException(
          'Section "$partId" có question_count=${questionCountField.toInt()} không khớp số câu thực tế=${questions.length}.',
        );
      }
      sections.add({
        'part_id': partId,
        'section_title': sectionTitle,
        'skill': skill,
        'part_order': partOrder.toInt(),
        'question_count': questionCountField.toInt(),
        'question_image': _readOptionalText(section['question_image']),
        'audio_asset':
            _readOptionalText(section['audio_asset']) ??
            _readOptionalText(section['question_audio']) ??
            _readOptionalText(section['listening_audio_asset']) ??
            _readOptionalText(section['listening_audio']) ??
            _readOptionalText(section['audio_listening']),
        'questions': questions,
      });
    }

    final totalQuestions = (decoded['total_questions'] as num?)?.toInt();
    if (totalQuestions == null) {
      throw const FormatException('Thiếu hoặc sai kiểu trường "total_questions".');
    }
    if (totalQuestions != questionCount) {
      throw FormatException(
        'total_questions=$totalQuestions không khớp tổng câu hỏi thực tế=$questionCount.',
      );
    }

    final normalized = <String, dynamic>{
      'schema_version': schemaVersion.toInt(),
      'exam_code': examCode,
      'level': level,
      'title': title,
      'total_questions': totalQuestions,
      'time_limit_minutes': timeLimitMinutes.toInt(),
      'audio_listening': audioListening,
      'listening_audio_asset':
          _readOptionalText(decoded['listening_audio_asset']) ??
          _readOptionalText(decoded['listening_audio']) ??
          audioListening,
      'sections': sections,
    };

    return ParsedHskExam(
      examCode: examCode,
      level: level,
      title: title,
      totalQuestions: totalQuestions,
      sectionCount: sections.length,
      normalizedJson: normalized,
    );
  }

  String _readRequiredText(Object? value, String fieldName) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw FormatException('Thiếu hoặc rỗng trường "$fieldName".');
    }
    return text;
  }

  String? _readOptionalText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  /// HSK1–3: chỉ form cơ bản; HSK4+ mới có sort_sentences / sort_word / write_sentence.
  static bool levelAllowsExtendedQuestionTypes(String level) {
    final u = level.trim().toUpperCase();
    final match = RegExp(r'^HSK(\d+)$').firstMatch(u);
    if (match == null) {
      return false;
    }
    final n = int.tryParse(match.group(1)!);
    return n != null && n >= 4;
  }

  String _normalizeAnswerText(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*:\s*'), ': ')
        .trim();
  }

  void _assertAllowedQuestionType({
    required String questionType,
    required String level,
    required String code,
    required String partId,
  }) {
    if (_baseQuestionTypes.contains(questionType)) {
      return;
    }
    if (_extendedFormQuestionTypes.contains(questionType)) {
      if (!levelAllowsExtendedQuestionTypes(level)) {
        throw FormatException(
          'Question "$code" (section "$partId"): question_type "$questionType" chỉ được dùng từ HSK4 trở lên (HSK4–HSK6).',
        );
      }
      return;
    }
    throw FormatException(
      'Question "$code" (section "$partId"): question_type "$questionType" không được hỗ trợ.',
    );
  }

  void _validateQuestionPayload({
    required String questionType,
    required String code,
    required String partId,
    required String questionText,
    required List<String> options,
    required String correctAnswer,
  }) {
    switch (questionType) {
      case 'true_false':
      case 'single_choice':
        if (options.isEmpty) {
          throw FormatException(
            'Question "$code" của section "$partId" phải có ít nhất một option.',
          );
        }
        if (options.any((option) => option.isEmpty)) {
          throw FormatException(
            'Question "$code" của section "$partId" có option rỗng.',
          );
        }
        final normalizedCorrectAnswer = _normalizeAnswerText(correctAnswer);
        final normalizedOptions = options.map(_normalizeAnswerText).toSet();
        if (!normalizedOptions.contains(normalizedCorrectAnswer)) {
          throw FormatException(
            'correct_answer của question "$code" không nằm trong options.',
          );
        }
        return;

      case 'sort_sentences':
        if (options.length < 2) {
          throw FormatException(
            'Question "$code" (sort_sentences) cần ít nhất 2 options.',
          );
        }
        if (options.any((option) => option.isEmpty)) {
          throw FormatException(
            'Question "$code" (sort_sentences) có option rỗng.',
          );
        }
        final keys = options.map(_optionSortKey).toList();
        if (keys.any((k) => k.isEmpty)) {
          throw FormatException(
            'Question "$code" (sort_sentences): mỗi option cần dạng "A: ..." để nhận diện thứ tự.',
          );
        }
        final uniqueKeys = keys.toSet();
        if (uniqueKeys.length != keys.length) {
          throw FormatException(
            'Question "$code" (sort_sentences): các nhãn A/B/C trong options phải khác nhau.',
          );
        }
        _validateSortSentenceAnswer(
          correctAnswer: correctAnswer,
          expectedKeys: uniqueKeys,
          code: code,
        );
        return;

      case 'sort_word':
        if (questionText.isEmpty) {
          throw FormatException(
            'Question "$code" (sort_word) cần question_text chứa các từ (cách nhau bằng khoảng trắng).',
          );
        }
        if (correctAnswer.trim().isEmpty) {
          throw FormatException(
            'Question "$code" (sort_word) cần correct_answer (câu hoàn chỉnh).',
          );
        }
        return;

      case 'write_sentence':
        if (questionText.isEmpty) {
          throw FormatException(
            'Question "$code" (write_sentence) cần question_text (từ gợi ý).',
          );
        }
        if (correctAnswer.trim().isEmpty) {
          throw FormatException(
            'Question "$code" (write_sentence) cần correct_answer (câu mẫu).',
          );
        }
        return;

      default:
        throw FormatException('Lỗi nội bộ: kiểu câu "$questionType" chưa được xử lý.');
    }
  }

  String _optionSortKey(String option) {
    final colon = option.indexOf(':');
    if (colon <= 0) {
      return '';
    }
    return option.substring(0, colon).trim().toUpperCase();
  }

  void _validateSortSentenceAnswer({
    required String correctAnswer,
    required Set<String> expectedKeys,
    required String code,
  }) {
    final normalized = correctAnswer.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final parts = normalized.split('-').where((p) => p.isNotEmpty).toList();
    if (parts.length != expectedKeys.length) {
      throw FormatException(
        'Question "$code" (sort_sentences): correct_answer phải là thứ tự các nhãn nối bằng dấu gạch (ví dụ C-A-B), đủ ${expectedKeys.length} phần.',
      );
    }
    final partSet = parts.toSet();
    if (partSet.length != parts.length) {
      throw FormatException(
        'Question "$code" (sort_sentences): correct_answer không được trùng nhãn.',
      );
    }
    for (final p in parts) {
      if (!expectedKeys.contains(p)) {
        throw FormatException(
          'Question "$code" (sort_sentences): correct_answer chứa nhãn "$p" không khớp options.',
        );
      }
    }
  }
}
