import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostModel {
  const CommunityPostModel({
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.likedUserIds,
    required this.commentedUserIds,
    required this.interactedUserIds,
  });

  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;
  final List<String> likedUserIds;
  final List<String> commentedUserIds;
  final List<String> interactedUserIds;

  bool likedBy(String userId) => likedUserIds.contains(userId);

  factory CommunityPostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final json = doc.data() ?? <String, dynamic>{};
    final timestamp = json['created_at'];
    return CommunityPostModel(
      postId: (json['post_id'] ?? doc.id).toString(),
      userId: (json['user_id'] ?? '').toString(),
      userName: (json['user_name'] ?? '').toString(),
      userAvatar: (json['user_avatar'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      likedUserIds: _toStringList(json['liked_user_ids']),
      commentedUserIds: _toStringList(json['commented_user_ids']),
      interactedUserIds: _toStringList(json['interacted_user_ids']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
