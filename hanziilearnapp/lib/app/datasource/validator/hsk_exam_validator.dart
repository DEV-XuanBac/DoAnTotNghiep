import 'dart:convert';

import 'package:hanziilearnapp/app/models/parsed_hsk_exam_model.dart';

abstract class IHskExamValidator {
  ParsedHskExam parseAndValidate(String rawJson);
}

class HskExamValidator implements IHskExamValidator {
  @override
  ParsedHskExam parseAndValidate(String rawJson) {
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
        if (optionsRaw is! List || optionsRaw.isEmpty) {
          throw FormatException(
            'Question "$code" của section "$partId" phải có options.',
          );
        }
        final options = optionsRaw.map((option) => option.toString().trim()).toList();
        if (options.any((option) => option.isEmpty)) {
          throw FormatException(
            'Question "$code" của section "$partId" có option rỗng.',
          );
        }
        final correctAnswer = _readRequiredText(
          question['correct_answer'],
          'questions.correct_answer',
        );
        final normalizedCorrectAnswer = _normalizeAnswerText(correctAnswer);
        final normalizedOptions = options.map(_normalizeAnswerText).toSet();
        if (!normalizedOptions.contains(normalizedCorrectAnswer)) {
          throw FormatException(
            'correct_answer của question "$code" không nằm trong options.',
          );
        }

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

  String _normalizeAnswerText(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*:\s*'), ': ')
        .trim();
  }
}
