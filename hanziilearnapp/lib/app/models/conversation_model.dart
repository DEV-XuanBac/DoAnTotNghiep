/// Một lượt thoại trong đoạn hội thoại AI.
class ConversationMessage {
  final String speaker;
  final String chinese;
  final String pinyin;
  final String vietnamese;
  final bool isUserTurn;

  const ConversationMessage({
    required this.speaker,
    required this.chinese,
    required this.pinyin,
    required this.vietnamese,
    required this.isUserTurn,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      speaker: json['speaker'] as String? ?? '',
      chinese: json['chinese'] as String? ?? '',
      pinyin: json['pinyin'] as String? ?? '',
      vietnamese: json['vietnamese'] as String? ?? '',
      isUserTurn: json['isUserTurn'] as bool? ?? false,
    );
  }
}

/// Đoạn hội thoại hoàn chỉnh được AI tạo ra.
class ConversationDialogue {
  final String topicChinese;
  final String topicVietnamese;
  final String scenario;
  final List<ConversationMessage> messages;

  const ConversationDialogue({
    required this.topicChinese,
    required this.topicVietnamese,
    required this.scenario,
    required this.messages,
  });

  factory ConversationDialogue.fromJson(Map<String, dynamic> json) {
    final msgs = (json['messages'] as List<dynamic>? ?? [])
        .map((e) => ConversationMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return ConversationDialogue(
      topicChinese: json['topicChinese'] as String? ?? '',
      topicVietnamese: json['topicVietnamese'] as String? ?? '',
      scenario: json['scenario'] as String? ?? '',
      messages: msgs,
    );
  }
}

/// Chủ đề hội thoại với icon + tên hiển thị.
class ConversationTopic {
  final String id;
  final String nameVi;
  final String nameCn;
  final String icon;

  const ConversationTopic({
    required this.id,
    required this.nameVi,
    required this.nameCn,
    required this.icon,
  });
}
