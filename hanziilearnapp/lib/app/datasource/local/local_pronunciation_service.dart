import 'dart:math';

import 'package:hanziilearnapp/app/models/pronunciation_result.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Đánh giá phát âm bằng speech_to_text (on-device) + so sánh văn bản.
class LocalPronunciationService {
  static const _defaultConfidence = 0.5;
  static const _listenLocaleId = 'zh-CN';

  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;

  String _recognizedText = '';
  double _confidence = 0.0;

  bool get isListening => _stt.isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _stt.initialize();
    return _isInitialized;
  }

  Future<void> startListening({
    required void Function(String partialText) onPartialResult,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) throw Exception('Không thể khởi tạo nhận dạng giọng nói');
    }

    _recognizedText = '';
    _confidence = 0.0;

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        _recognizedText = result.recognizedWords;
        if (result.hasConfidenceRating) {
          _confidence = result.confidence;
        }
        onPartialResult(_recognizedText);
      },
      localeId: _listenLocaleId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  Future<PronunciationResult> stopAndAssess(String referenceText) async {
    await _stt.stop();

    if (_recognizedText.isEmpty) {
      return _emptyResult('Không nhận dạng được giọng nói. Hãy thử lại.');
    }

    return _evaluate(referenceText, _recognizedText, _confidence);
  }

  Future<void> cancel() async {
    await _stt.cancel();
  }

  void dispose() {
    _stt.cancel();
  }

  PronunciationResult _evaluate(
    String reference,
    String recognized,
    double sttConfidence,
  ) {
    final ref = _normalize(reference);
    final rec = _normalize(recognized);

    if (ref.isEmpty) {
      return _emptyResult('Câu tham chiếu trống', displayText: recognized);
    }

    final accuracy = _calcAccuracy(ref, rec);
    final completeness = _calcCompleteness(ref, rec);
    final fluency = _calcFluency(ref, rec, sttConfidence);

    return PronunciationResult(
      accuracyScore: accuracy,
      fluencyScore: fluency,
      completenessScore: completeness,
      displayText: recognized,
    );
  }

  String _normalize(String s) {
    return s.replaceAll(RegExp(r'[\s\p{P}\p{S}]', unicode: true), '');
  }

  double _calcAccuracy(String ref, String rec) {
    final lcs = _lcsLength(ref, rec);
    if (lcs == 0) return 0;
    return _toPercent(lcs / max(ref.length, rec.length));
  }

  double _calcCompleteness(String ref, String rec) {
    if (ref.isEmpty) return 0;
    final recChars = rec.split('');
    final remaining = List<String>.from(recChars);
    int matched = 0;
    for (final c in ref.split('')) {
      final idx = remaining.indexOf(c);
      if (idx != -1) {
        matched++;
        remaining.removeAt(idx);
      }
    }
    return _toPercent(matched / ref.length);
  }

  double _calcFluency(String ref, String rec, double sttConfidence) {
    final lengthRatio = rec.isEmpty
        ? 0.0
        : min(ref.length, rec.length) / max(ref.length, rec.length);
    final conf = sttConfidence > 0 ? sttConfidence : _defaultConfidence;
    return _toPercent(conf * 0.6 + lengthRatio * 0.4);
  }

  int _lcsLength(String a, String b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
      }
    }
    return dp[m][n];
  }

  double _toPercent(num value) => (value * 100).clamp(0, 100).toDouble();

  PronunciationResult _emptyResult(
    String message, {
    String displayText = '',
  }) {
    return PronunciationResult(
      accuracyScore: 0,
      fluencyScore: 0,
      completenessScore: 0,
      displayText: displayText,
      errorMessage: message,
    );
  }
}
