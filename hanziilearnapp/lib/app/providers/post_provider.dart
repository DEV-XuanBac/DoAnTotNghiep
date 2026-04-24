import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hanziilearnapp/app/models/community_comment_model.dart';
import 'package:hanziilearnapp/app/models/community_post_model.dart';

class PostProvider extends ChangeNotifier {
  PostProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection('posts');
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<Map<String, String>> watchCurrentUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const {'name': 'Người dùng', 'avatar': ''});
    }
    return _usersRef.doc(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      final name = (data['usename_vie'] ?? user.email ?? 'Người dùng')
          .toString()
          .trim();
      final avatar = (data['avatar'] ?? '').toString().trim();
      return {'name': name, 'avatar': avatar};
    });
  }

  Stream<List<CommunityPostModel>> watchAllPosts() {
    return _postsRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(CommunityPostModel.fromFirestore).toList();
        });
  }

  Stream<List<CommunityCommentModel>> watchComments(String postId) {
    return _postsRef
        .doc(postId)
        .collection('comments')
        .orderBy('created_at')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(CommunityCommentModel.fromFirestore)
              .toList();
        });
  }

  Stream<List<CommunityPostModel>> watchManagedPosts(String userId) {
    return _postsRef
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs.map(CommunityPostModel.fromFirestore).toList();
          posts.sort((a, b) {
            final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bt.compareTo(at);
          });
          return posts;
        });
  }

  Stream<List<CommunityPostModel>> watchInteractedPosts(String userId) {
    return _postsRef
        .where('interacted_user_ids', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map(CommunityPostModel.fromFirestore)
              .where((post) => post.userId != userId)
              .toList();
          posts.sort((a, b) {
            final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
            final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
            return bt.compareTo(at);
          });
          return posts;
        });
  }

  Future<void> createPost(String content) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để đăng bài.');
    }
    final cleanedContent = content.trim();
    if (cleanedContent.isEmpty) {
      throw Exception('Nội dung bài đăng không được để trống.');
    }

    final profile = await _usersRef.doc(user.uid).get();
    final profileData = profile.data() ?? <String, dynamic>{};
    final userName = (profileData['usename_vie'] ?? user.email ?? 'Người dùng')
        .toString();
    final userAvatar = (profileData['avatar'] ?? '').toString();

    final doc = _postsRef.doc();
    await doc.set({
      'post_id': doc.id,
      'user_id': user.uid,
      'user_name': userName,
      'user_avatar': userAvatar,
      'content': cleanedContent,
      'like_count': 0,
      'comment_count': 0,
      'created_at': FieldValue.serverTimestamp(),
      'liked_user_ids': <String>[],
      'commented_user_ids': <String>[],
      'interacted_user_ids': <String>[],
    });
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xóa bài.');
    }

    final doc = await _postsRef.doc(postId).get();
    final ownerId = (doc.data()?['user_id'] ?? '').toString();
    if (ownerId != user.uid) {
      throw Exception('Bạn không có quyền xóa bài này.');
    }
    await _postsRef.doc(postId).delete();
  }

  Future<void> toggleLike(CommunityPostModel post) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để tương tác.');
    }

    final postRef = _postsRef.doc(post.postId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final likedUsers = _toStringList(data['liked_user_ids']);
      final interactedUsers = _toStringList(data['interacted_user_ids']);

      final hasLiked = likedUsers.contains(user.uid);
      if (hasLiked) {
        likedUsers.remove(user.uid);
      } else {
        likedUsers.add(user.uid);
      }

      if (likedUsers.contains(user.uid) ||
          _toStringList(data['commented_user_ids']).contains(user.uid)) {
        if (!interactedUsers.contains(user.uid)) {
          interactedUsers.add(user.uid);
        }
      } else {
        interactedUsers.remove(user.uid);
      }

      transaction.update(postRef, {
        'liked_user_ids': likedUsers,
        'interacted_user_ids': interactedUsers,
        'like_count': likedUsers.length,
      });
    });
  }

  Future<void> addComment(
    String postId,
    String commentContent, {
    String parentCommentId = '',
    String parentUserId = '',
    String parentUserName = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để bình luận.');
    }

    final cleanedComment = commentContent.trim();
    if (cleanedComment.isEmpty) {
      throw Exception('Nội dung bình luận không được để trống.');
    }

    final profile = await _usersRef.doc(user.uid).get();
    final profileData = profile.data() ?? <String, dynamic>{};
    final userName = (profileData['usename_vie'] ?? user.email ?? 'Người dùng')
        .toString();
    final userAvatar = (profileData['avatar'] ?? '').toString();

    final postRef = _postsRef.doc(postId);
    final commentRef = postRef.collection('comments').doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final commentedUsers = _toStringList(data['commented_user_ids']);
      final interactedUsers = _toStringList(data['interacted_user_ids']);

      if (!commentedUsers.contains(user.uid)) {
        commentedUsers.add(user.uid);
      }
      if (!interactedUsers.contains(user.uid)) {
        interactedUsers.add(user.uid);
      }

      transaction.set(commentRef, {
        'comment_id': commentRef.id,
        'post_id': postId,
        'user_id': user.uid,
        'user_name': userName,
        'user_avatar': userAvatar,
        'content': cleanedComment,
        'created_at': FieldValue.serverTimestamp(),
        'parent_comment_id': parentCommentId,
        'parent_user_id': parentUserId,
        'parent_user_name': parentUserName,
        'is_reply': parentCommentId.isNotEmpty,
      });
      transaction.update(postRef, {
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
