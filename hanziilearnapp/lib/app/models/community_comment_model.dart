import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityCommentModel {
  const CommunityCommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    required this.parentCommentId,
    required this.parentUserId,
    required this.parentUserName,
    required this.isReply,
  });

  final String commentId;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime? createdAt;
  final String parentCommentId;
  final String parentUserId;
  final String parentUserName;
  final bool isReply;

  factory CommunityCommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final json = doc.data() ?? <String, dynamic>{};
    final timestamp = json['created_at'];
    return CommunityCommentModel(
      commentId: (json['comment_id'] ?? doc.id).toString(),
      postId: (json['post_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      userName: (json['user_name'] ?? '').toString(),
      userAvatar: (json['user_avatar'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      parentCommentId: (json['parent_comment_id'] ?? '').toString(),
      parentUserId: (json['parent_user_id'] ?? '').toString(),
      parentUserName: (json['parent_user_name'] ?? '').toString(),
      isReply: json['is_reply'] == true,
    );
  }
}
