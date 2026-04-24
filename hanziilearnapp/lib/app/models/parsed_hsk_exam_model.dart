class ParsedHskExam {
  const ParsedHskExam({
    required this.examCode,
    required this.level,
    required this.title,
    required this.totalQuestions,
    required this.sectionCount,
    required this.normalizedJson,
  });

  final String examCode;
  final String level;
  final String title;
  final int totalQuestions;
  final int sectionCount;
  final Map<String, dynamic> normalizedJson;
}
