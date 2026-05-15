import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hanziilearnapp/app/datasource/repository/post_repository.dart';
import 'package:hanziilearnapp/app/models/community_comment_model.dart';
import 'package:hanziilearnapp/app/models/community_post_model.dart';

class PostProvider extends ChangeNotifier {
  PostProvider({FirebaseAuth? auth, IPostRepository? repository})
    : _auth = auth ?? FirebaseAuth.instance,
      _repo = repository ?? PostRepository();

  final FirebaseAuth _auth;
  final IPostRepository _repo;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<Map<String, String>> watchCurrentUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const {'name': 'Người dùng', 'avatar': ''});
    }
    return _repo.watchUserProfile(user.uid).map((data) {
      final profile = data ?? <String, dynamic>{};
      final name = (profile['usename_vie'] ?? user.email ?? 'Người dùng')
          .toString()
          .trim();
      final avatar = (profile['avatar'] ?? '').toString().trim();
      return {'name': name, 'avatar': avatar};
    });
  }

  Stream<List<CommunityPostModel>> watchAllPosts() => _repo.watchAllPosts();

  Stream<List<CommunityCommentModel>> watchComments(String postId) =>
      _repo.watchComments(postId);

  Stream<List<CommunityPostModel>> watchManagedPosts(String userId) =>
      _repo.watchManagedPosts(userId);

  Stream<List<CommunityPostModel>> watchInteractedPosts(String userId) =>
      _repo.watchInteractedPosts(userId);

  Future<void> createPost(String content) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để đăng bài.');
    }
    final cleanedContent = content.trim();
    if (cleanedContent.isEmpty) {
      throw Exception('Nội dung bài đăng không được để trống.');
    }

    final profileData = await _repo.getUserProfile(user.uid) ?? <String, dynamic>{};
    final userName = (profileData['usename_vie'] ?? user.email ?? 'Người dùng')
        .toString();
    final userAvatar = (profileData['avatar'] ?? '').toString();

    await _repo.createPost(
      userId: user.uid,
      userName: userName,
      userAvatar: userAvatar,
      content: cleanedContent,
    );
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để xóa bài.');
    }

    final owner = await _repo.readPostOwner(postId);
    if (owner.ownerId != user.uid) {
      throw Exception('Bạn không có quyền xóa bài này.');
    }
    await _repo.deletePost(postId);
  }

  Future<void> toggleLike(CommunityPostModel post) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập để tương tác.');
    }
    await _repo.runLikeTransaction(postId: post.postId, userId: user.uid);
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

    final profileData = await _repo.getUserProfile(user.uid) ?? <String, dynamic>{};
    final userName = (profileData['usename_vie'] ?? user.email ?? 'Người dùng')
        .toString();
    final userAvatar = (profileData['avatar'] ?? '').toString();

    await _repo.runAddCommentTransaction(
      postId: postId,
      userId: user.uid,
      userName: userName,
      userAvatar: userAvatar,
      content: cleanedComment,
      parentCommentId: parentCommentId,
      parentUserId: parentUserId,
      parentUserName: parentUserName,
    );
  }
}
