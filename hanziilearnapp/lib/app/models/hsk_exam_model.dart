class HskExam {
  const HskExam({
    required this.examCode,
    required this.level,
    required this.title,
    required this.totalQuestions,
    required this.assetPath,
  });

  final String examCode;
  final String level;
  final String title;
  final int totalQuestions;
  final String assetPath;

  factory HskExam.fromJson(Map<String, dynamic> json, String assetPath) {
    return HskExam(
      examCode: (json['exam_code'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      assetPath: assetPath,
    );
  }
}

class HskExamDetail {
  const HskExamDetail({
    required this.examCode,
    required this.level,
    required this.title,
    required this.totalQuestions,
    required this.sections,
    this.listeningAudioAsset,
  });

  final String examCode;
  final String level;
  final String title;
  final int totalQuestions;
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
      sections: rawSections.map(HskExamSection.fromJson).toList(),
      listeningAudioAsset: _readNullableString(
            json['listening_audio_asset'],
          ) ??
          _readNullableString(json['listening_audio']),
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
      audioAsset: _readNullableString(json['audio_asset']) ??
          _readNullableString(json['question_audio']) ??
          _readNullableString(json['listening_audio_asset']) ??
          _readNullableString(json['listening_audio']),
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
