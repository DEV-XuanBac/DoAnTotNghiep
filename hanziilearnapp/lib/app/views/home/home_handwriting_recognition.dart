import 'dart:async';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hanziilearnapp/app/datasource/network_services/google_vision_handwriting_service.dart';

/// Nhận diện chữ viết tay từ ảnh (Vision API nếu bật, fallback ML Kit).
class HomeHandwritingRecognition {
  const HomeHandwritingRecognition(this._visionOcr);

  final GoogleVisionHandwritingService _visionOcr;

  Future<String> recognizeFromImagePath(
    String imagePath, {
    required bool isViMode,
  }) async {
    if (_visionOcr.isEnabled) {
      try {
        final cloudText = await _visionOcr.recognizeFromImagePath(
          imagePath,
          isViMode: isViMode,
        );
        final normalized = normalizeQuery(cloudText, isViMode: isViMode);
        if (normalized.isNotEmpty) {
          return normalized;
        }
      } catch (_) {}
    }

    final recognizer = TextRecognizer(
      script: isViMode
          ? TextRecognitionScript.latin
          : TextRecognitionScript.chinese,
    );
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return extractFromRecognized(result, isViMode: isViMode);
    } finally {
      unawaited(recognizer.close());
    }
  }

  static String extractFromRecognized(
    RecognizedText recognized, {
    required bool isViMode,
  }) {
    final lines = recognized.blocks
        .expand((block) => block.lines)
        .map((line) => line.text.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return '';
    }

    if (isViMode) {
      final merged = lines.join(' ');
      return normalizeQuery(merged, isViMode: true);
    }

    final merged = lines.join();
    return normalizeQuery(merged, isViMode: false);
  }

  static String normalizeQuery(String raw, {required bool isViMode}) {
    if (isViMode) {
      return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return raw
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\p{Script=Han}a-zA-Z0-9]', unicode: true), '')
        .trim();
  }
}
