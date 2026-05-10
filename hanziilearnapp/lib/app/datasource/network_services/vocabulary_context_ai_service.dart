import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

/// Dùng Gemini để giải thích cách dùng từ trong ngữ cảnh cụ thể.
class VocabularyContextAiService {
  VocabularyContextAiService({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;

  static const _models = ['gemini-2.5-flash-lite', 'gemini-2.5-flash'];

  static const int _maxRetries = 2;

  Future<String> explainUsage({
    required Word word,
    required String userQuery,
  }) async {
    final prompt = _buildPrompt(word: word, userQuery: userQuery);
    for (final model in _models) {
      try {
        return await _tryGenerate(model, prompt);
      } on GenerativeAIException catch (e) {
        final msg = e.message.toLowerCase();
        final isRateLimit =
            msg.contains('quota') ||
            msg.contains('rate') ||
            msg.contains('429');
        if (!isRateLimit || model == _models.last) {
          rethrow;
        }
      }
    }
    return '';
  }

  Future<String> _tryGenerate(String modelName, String prompt) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.5,
        maxOutputTokens: 400,
      ),
    );

    Object? lastError;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final rs = await model.generateContent([Content.text(prompt)]);
        return (rs.text ?? '').trim();
      } catch (e) {
        lastError = e;
        final msg = e.toString().toLowerCase();
        final isRetryable =
            msg.contains('quota') ||
            msg.contains('rate') ||
            msg.contains('429') ||
            msg.contains('503') ||
            msg.contains('overloaded');
        if (!isRetryable) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    throw lastError ?? Exception('Hệ thống đang bận. Vui lòng thử lại sau.');
  }

  String _buildPrompt({required Word word, required String userQuery}) {
    return '''
Bạn là trợ giảng tiếng Trung cho người Việt.
Hãy giải thích ngắn gọn cách dùng từ trong ngữ cảnh thực tế.

Thông tin từ:
- Hanzi: ${word.hanzi}
- Pinyin: ${word.pinyin}
- Nghĩa: ${word.meaning}
- Từ người dùng đã nhập để tìm: $userQuery

Yêu cầu:
- Trả lời bằng tiếng Việt, rõ ràng, dễ hiểu.
- Độ dài 2-3 câu ngắn.
- Nêu sắc thái/cách dùng đúng ngữ cảnh.
- Cho 1 ví dụ câu tiếng Trung thật ngắn + nghĩa tiếng Việt.
- Không dùng markdown, không đánh số.
''';
  }
}
