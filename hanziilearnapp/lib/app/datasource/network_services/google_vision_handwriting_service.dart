import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class GoogleVisionHandwritingService {
  const GoogleVisionHandwritingService({required this.apiKey});

  final String apiKey;

  bool get isEnabled => apiKey.trim().isNotEmpty;

  Future<String> recognizeFromImagePath(
    String imagePath, {
    required bool isViMode,
  }) async {
    if (!isEnabled) {
      return '';
    }

    final bytes = await File(imagePath).readAsBytes();
    final encoded = base64Encode(bytes);

    final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': encoded},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION'},
            ],
            'imageContext': {
              'languageHints': isViMode ? ['vi'] : ['zh', 'zh-Hans'],
            },
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'Google Vision request failed: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return '';
    }
    final responses = decoded['responses'];
    if (responses is! List || responses.isEmpty) {
      return '';
    }
    final first = responses.first;
    if (first is! Map<String, dynamic>) {
      return '';
    }
    final error = first['error'];
    if (error is Map<String, dynamic>) {
      throw HttpException(
        'Google Vision OCR error: ${error['message'] ?? 'unknown'}',
      );
    }

    final fullText = first['fullTextAnnotation'];
    if (fullText is Map<String, dynamic>) {
      return (fullText['text'] ?? '').toString().trim();
    }

    final textAnnotations = first['textAnnotations'];
    if (textAnnotations is List && textAnnotations.isNotEmpty) {
      final firstText = textAnnotations.first;
      if (firstText is Map<String, dynamic>) {
        return (firstText['description'] ?? '').toString().trim();
      }
    }

    return '';
  }
}
