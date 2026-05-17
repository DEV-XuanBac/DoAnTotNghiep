import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityAnnouncementModel {
  const CommunityAnnouncementModel({
    required this.content,
    required this.updatedAt,
    required this.isActive,
  });

  final String content;
  final DateTime? updatedAt;
  final bool isActive;

  bool get isVisible => isActive && content.trim().isNotEmpty;

  factory CommunityAnnouncementModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final json = doc.data() ?? <String, dynamic>{};
    final timestamp = json['updated_at'];
    return CommunityAnnouncementModel(
      content: (json['content'] ?? '').toString(),
      updatedAt: timestamp is Timestamp ? timestamp.toDate() : null,
      isActive: json['is_active'] == true,
    );
  }
}
