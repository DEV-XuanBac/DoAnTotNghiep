/// Kết quả đánh giá phát âm.
class PronunciationResult {
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final double? prosodyScore;
  final String displayText;
  final String? errorMessage;

  const PronunciationResult({
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    this.prosodyScore,
    required this.displayText,
    this.errorMessage,
  });

  double get overallScore =>
      (accuracyScore + fluencyScore + completenessScore) / 3;
}
