import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hanziilearnapp/app/models/conversation_model.dart';

/// Service gọi Google Gemini để tạo đoạn hội thoại tiếng Trung theo chủ đề.
class ConversationAiService {
  ConversationAiService({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;

  static const _models = [
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
  ];

  static const int _maxRetries = 3;

  static const List<ConversationTopic> availableTopics = [
    ConversationTopic(
      id: 'school',
      nameVi: 'Trường học',
      nameCn: '学校',
      icon: '🏫',
    ),
    ConversationTopic(
      id: 'office',
      nameVi: 'Văn phòng',
      nameCn: '办公室',
      icon: '🏢',
    ),
    ConversationTopic(
      id: 'shopping',
      nameVi: 'Mua sắm',
      nameCn: '购物',
      icon: '🛒',
    ),
    ConversationTopic(
      id: 'restaurant',
      nameVi: 'Nhà hàng',
      nameCn: '餐厅',
      icon: '🍜',
    ),
    ConversationTopic(
      id: 'travel',
      nameVi: 'Du lịch',
      nameCn: '旅游',
      icon: '✈️',
    ),
    ConversationTopic(
      id: 'hospital',
      nameVi: 'Bệnh viện',
      nameCn: '医院',
      icon: '🏥',
    ),
    ConversationTopic(
      id: 'daily',
      nameVi: 'Sinh hoạt hàng ngày',
      nameCn: '日常生活',
      icon: '🏠',
    ),
    ConversationTopic(
      id: 'greeting',
      nameVi: 'Chào hỏi',
      nameCn: '问候',
      icon: '👋',
    ),
  ];

  Future<ConversationDialogue> genDlg({
    required ConversationTopic topic,
    int level = 2,
  }) async {
    final prompt = _buildPrompt(topic, level);

    for (final model in _models) {
      try {
        return await _tryGenerate(model, prompt);
      } on GenerativeAIException catch (e) {
        final msg = e.message.toLowerCase();
        final isRateLimit =
            msg.contains('quota') || msg.contains('rate') || msg.contains('429');
        if (!isRateLimit || model == _models.last) rethrow;
      }
    }

    throw Exception('Tất cả model đều bị lỗi. Vui lòng thử lại sau.');
  }

  Future<ConversationDialogue> _tryGenerate(
    String modelName,
    String prompt,
  ) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.9,
        maxOutputTokens: 2048,
        responseMimeType: 'application/json',
      ),
    );

    Object? lastError;

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response =
            await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text == null || text.isEmpty) {
          throw Exception('Gemini không trả về kết quả');
        }

        final jsonStr = _extractJson(text);
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        return ConversationDialogue.fromJson(data);
      } catch (e) {
        lastError = e;
        final msg = e.toString().toLowerCase();
        final isRetryable = msg.contains('quota') ||
            msg.contains('rate') ||
            msg.contains('429') ||
            msg.contains('503') ||
            msg.contains('overloaded');
        if (!isRetryable) rethrow;

        final delay = Duration(seconds: 3 * (attempt + 1));
        await Future<void>.delayed(delay);
      }
    }

    if (lastError is Exception) {
      throw lastError;
    }
    if (lastError is Error) {
      throw lastError;
    }
    throw Exception(
      lastError == null
          ? 'Không thể tạo hội thoại'
          : 'Không thể tạo hội thoại: $lastError',
    );
  }

  String _buildPrompt(ConversationTopic topic, int level) {
    return '''
Bạn là một giáo viên dạy tiếng Trung cho người Việt Nam.
Hãy tạo một đoạn hội thoại tiếng Trung về chủ đề "${topic.nameCn}" (${topic.nameVi}) phù hợp trình độ HSK$level.

Yêu cầu:
- Đoạn hội thoại gồm 6-8 lượt thoại giữa 2 người (A và B)
- Người B là người học (isUserTurn = true), người A là đối tác hội thoại (isUserTurn = false)
- Xen kẽ lượt A và B, bắt đầu từ A
- Mỗi câu phải tự nhiên, thực tế, dễ hiểu
- Độ dài mỗi câu: 5-15 từ tiếng Trung

Trả về JSON duy nhất với cấu trúc:
{
  "topicChinese": "chủ đề bằng tiếng Trung",
  "topicVietnamese": "chủ đề bằng tiếng Việt",
  "scenario": "mô tả ngắn tình huống bằng tiếng Việt",
  "messages": [
    {
      "speaker": "A" hoặc "B",
      "chinese": "câu tiếng Trung (chữ Hán)",
      "pinyin": "phiên âm pinyin có dấu thanh",
      "vietnamese": "nghĩa tiếng Việt",
      "isUserTurn": false hoặc true
    }
  ]
}

CHỈ trả về JSON, không thêm text hay giải thích nào khác.
''';
  }

  String _extractJson(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      final firstNewline = s.indexOf('\n');
      if (firstNewline != -1) s = s.substring(firstNewline + 1);
      if (s.endsWith('```')) s = s.substring(0, s.length - 3);
      s = s.trim();
    }
    return s;
  }
}
