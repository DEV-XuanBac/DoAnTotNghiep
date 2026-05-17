import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanziilearnapp/app/models/community_announcement_model.dart';
import 'package:hanziilearnapp/app/models/community_comment_model.dart';
import 'package:hanziilearnapp/app/models/community_post_model.dart';

/// Truy cập collection `posts` cộng đồng (post + sub-collection `comments`).
abstract class IPostRepository {
  Stream<Map<String, dynamic>?> watchUserProfile(String? userId);

  Stream<List<CommunityPostModel>> watchAllPosts();

  Stream<List<CommunityCommentModel>> watchComments(String postId);

  Stream<List<CommunityPostModel>> watchManagedPosts(String userId);

  Stream<List<CommunityPostModel>> watchInteractedPosts(String userId);

  Stream<CommunityAnnouncementModel?> watchCommunityAnnouncement();

  Future<Map<String, dynamic>?> getUserProfile(String userId);

  Future<void> createPost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
  });

  Future<({String ownerId, bool exists})> readPostOwner(String postId);

  Future<void> deletePost(String postId);

  Future<void> runLikeTransaction({
    required String postId,
    required String userId,
  });

  Future<void> runAddCommentTransaction({
    required String postId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
    required String parentCommentId,
    required String parentUserId,
    required String parentUserName,
  });
}

class PostRepository implements IPostRepository {
  PostRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _announcementDocPath = 'community_config/announcement';

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<Map<String, dynamic>?> watchUserProfile(String? userId) {
    if (userId == null) {
      return Stream<Map<String, dynamic>?>.value(null);
    }
    return _users.doc(userId).snapshots().map((snapshot) => snapshot.data());
  }

  @override
  Stream<List<CommunityPostModel>> watchAllPosts() {
    return _posts
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(CommunityPostModel.fromFirestore).toList(),
        );
  }

  @override
  Stream<List<CommunityCommentModel>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('created_at')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(CommunityCommentModel.fromFirestore).toList(),
        );
  }

  @override
  Stream<List<CommunityPostModel>> watchManagedPosts(String userId) {
    return _posts.where('user_id', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final posts = snapshot.docs.map(CommunityPostModel.fromFirestore).toList()
        ..sort((a, b) {
          final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return bt.compareTo(at);
        });
      return posts;
    });
  }

  @override
  Stream<List<CommunityPostModel>> watchInteractedPosts(String userId) {
    return _posts
        .where('interacted_user_ids', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final posts =
              snapshot.docs
                  .map(CommunityPostModel.fromFirestore)
                  .where((post) => post.userId != userId)
                  .toList()
                ..sort((a, b) {
                  final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
                  final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
                  return bt.compareTo(at);
                });
          return posts;
        });
  }

  @override
  Stream<CommunityAnnouncementModel?> watchCommunityAnnouncement() {
    return _firestore.doc(_announcementDocPath).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return CommunityAnnouncementModel.fromFirestore(snapshot);
    });
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _users.doc(userId).get();
    return doc.data();
  }

  @override
  Future<void> createPost({
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
  }) async {
    final doc = _posts.doc();
    await doc.set({
      'post_id': doc.id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'content': content,
      'like_count': 0,
      'comment_count': 0,
      'created_at': FieldValue.serverTimestamp(),
      'liked_user_ids': <String>[],
      'commented_user_ids': <String>[],
      'interacted_user_ids': <String>[],
    });
  }

  @override
  Future<({String ownerId, bool exists})> readPostOwner(String postId) async {
    final doc = await _posts.doc(postId).get();
    final data = doc.data();
    return (ownerId: (data?['user_id'] ?? '').toString(), exists: doc.exists);
  }

  @override
  Future<void> deletePost(String postId) => _posts.doc(postId).delete();

  @override
  Future<void> runLikeTransaction({
    required String postId,
    required String userId,
  }) {
    final postRef = _posts.doc(postId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final likedUsers = _toStringList(data['liked_user_ids']);
      final interactedUsers = _toStringList(data['interacted_user_ids']);

      final hasLiked = likedUsers.contains(userId);
      if (hasLiked) {
        likedUsers.remove(userId);
      } else {
        likedUsers.add(userId);
      }

      final commentedUsers = _toStringList(data['commented_user_ids']);
      if (likedUsers.contains(userId) || commentedUsers.contains(userId)) {
        if (!interactedUsers.contains(userId)) {
          interactedUsers.add(userId);
        }
      } else {
        interactedUsers.remove(userId);
      }

      transaction.update(postRef, {
        'liked_user_ids': likedUsers,
        'interacted_user_ids': interactedUsers,
        'like_count': likedUsers.length,
      });
    });
  }

  @override
  Future<void> runAddCommentTransaction({
    required String postId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
    required String parentCommentId,
    required String parentUserId,
    required String parentUserName,
  }) {
    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('comments').doc();
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final commentedUsers = _toStringList(data['commented_user_ids']);
      final interactedUsers = _toStringList(data['interacted_user_ids']);

      if (!commentedUsers.contains(userId)) {
        commentedUsers.add(userId);
      }
      if (!interactedUsers.contains(userId)) {
        interactedUsers.add(userId);
      }

      transaction
        ..set(commentRef, {
          'comment_id': commentRef.id,
          'post_id': postId,
          'user_id': userId,
          'user_name': userName,
          'user_avatar': userAvatar,
          'content': content,
          'created_at': FieldValue.serverTimestamp(),
          'parent_comment_id': parentCommentId,
          'parent_user_id': parentUserId,
          'parent_user_name': parentUserName,
          'is_reply': parentCommentId.isNotEmpty,
        })
        ..update(postRef, {
          'comment_count': ((data['comment_count'] as num?)?.toInt() ?? 0) + 1,
          'commented_user_ids': commentedUsers,
          'interacted_user_ids': interactedUsers,
        });
    });
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return <String>[];
  }
}
