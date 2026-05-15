/// Kết quả từng câu của một lượt làm đề.
class ExamQuestionResult {
  const ExamQuestionResult({
    required this.questionId,
    required this.correctAnswer,
    required this.isCorrect,
    this.selectedAnswer,
  });

  final int questionId;
  final String? selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;

  Map<String, dynamic> toFirestore() {
    return {
      'question_id': questionId,
      'selected_answer': selectedAnswer,
      'correct_answer': correctAnswer,
      'is_correct': isCorrect,
    };
  }

  factory ExamQuestionResult.fromFirestore(Map<String, dynamic> json) {
    final rawSelected = json['selected_answer'];
    return ExamQuestionResult(
      questionId: (json['question_id'] as num?)?.toInt() ?? 0,
      selectedAnswer: rawSelected?.toString(),
      correctAnswer: (json['correct_answer'] ?? '').toString(),
      isCorrect: (json['is_correct'] ?? false) == true,
    );
  }
}

/// Chi tiết lượt làm đề gần nhất của user.
class ExamAttemptDetail {
  const ExamAttemptDetail({
    required this.examId,
    required this.attemptNumber,
    required this.scoreOutOf10,
    required this.correctCount,
    required this.totalQuestions,
    required this.questionResults,
  });

  final String examId;
  final int attemptNumber;
  final double scoreOutOf10;
  final int correctCount;
  final int totalQuestions;
  final List<ExamQuestionResult> questionResults;

  List<ExamQuestionResult> get wrongResults =>
      questionResults.where((r) => !r.isCorrect).toList();

  int get wrongCount => totalQuestions - correctCount;
}
