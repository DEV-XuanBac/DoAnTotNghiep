class HskExam {
  const HskExam({
    required this.id,
    required this.examCode,
    required this.level,
    required this.title,
    required this.totalQuestions,
  });

  final String id;
  final String examCode;
  final String level;
  final String title;
  final int totalQuestions;

  factory HskExam.fromFirestore(String id, Map<String, dynamic> json) {
    final examData = (json['examData'] as Map<String, dynamic>?) ?? json;
    return HskExam(
      id: id,
      examCode:
          (examData['exam_code'] ?? json['examCode'] ?? json['exam_code'] ?? '')
              .toString(),
      level: (examData['level'] ?? json['level'] ?? '').toString(),
      title: (examData['title'] ?? json['title'] ?? '').toString(),
      totalQuestions:
          (examData['total_questions'] as num?)?.toInt() ??
          (json['totalQuestions'] as num?)?.toInt() ??
          0,
    );
  }
}

class HskExamDetail {
  const HskExamDetail({
    required this.examCode,
    required this.level,
    required this.title,
    required this.totalQuestions,
    required this.timeLimitMinutes,
    required this.sections,
    this.listeningAudioAsset,
  });

  final String examCode;
  final String level;
  final String title;
  final int totalQuestions;
  final int timeLimitMinutes;
  final List<HskExamSection> sections;
  final String? listeningAudioAsset;

  List<HskExamQuestion> get allQuestions {
    return sections.expand((section) => section.questions).toList();
  }

  factory HskExamDetail.fromJson(Map<String, dynamic> json) {
    final rawSections = (json['sections'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return HskExamDetail(
      examCode: (json['exam_code'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      timeLimitMinutes: (json['time_limit_minutes'] as num?)?.toInt() ?? 0,
      sections: rawSections.map(HskExamSection.fromJson).toList(),
      listeningAudioAsset:
          _readNullableString(json['listening_audio_asset']) ??
          _readNullableString(json['listening_audio']) ??
          _readNullableString(json['audio_listening']),
    );
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class HskExamSection {
  const HskExamSection({
    required this.partId,
    required this.sectionTitle,
    required this.skill,
    required this.questions,
    this.questionImage,
    this.audioAsset,
  });

  final String partId;
  final String sectionTitle;
  final String skill;
  final List<HskExamQuestion> questions;
  final String? questionImage;
  final String? audioAsset;

  factory HskExamSection.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return HskExamSection(
      partId: (json['part_id'] ?? '').toString(),
      sectionTitle: (json['section_title'] ?? '').toString(),
      skill: (json['skill'] ?? '').toString(),
      questions: rawQuestions.map(HskExamQuestion.fromJson).toList(),
      questionImage: _readNullableString(json['question_image']),
      audioAsset:
          _readNullableString(json['audio_asset']) ??
          _readNullableString(json['question_audio']) ??
          _readNullableString(json['listening_audio_asset']) ??
          _readNullableString(json['listening_audio']) ??
          _readNullableString(json['audio_listening']),
    );
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class HskExamQuestion {
  const HskExamQuestion({
    required this.questionId,
    required this.code,
    required this.questionType,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });

  final int questionId;
  final String code;
  final String questionType;
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  factory HskExamQuestion.fromJson(Map<String, dynamic> json) {
    return HskExamQuestion(
      questionId: (json['question_id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      questionType: (json['question_type'] ?? '').toString(),
      questionText: (json['question_text'] ?? '').toString(),
      options: (json['options'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      correctAnswer: (json['correct_answer'] ?? '').toString(),
    );
  }
}
