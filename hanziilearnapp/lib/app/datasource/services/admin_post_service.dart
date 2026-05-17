import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanziilearnapp/app/models/community_announcement_model.dart';
import 'package:hanziilearnapp/app/models/community_post_model.dart';

class AdminPostService {
  AdminPostService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _announcementDocPath = 'community_config/announcement';

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> get _announcementRef =>
      _firestore.doc(_announcementDocPath);

  Future<List<({String userId, String username})>> findUsersByUsername(
    String query,
  ) async {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return const [];
    }

    final snapshot = await _users.get();
    final matches = <({String userId, String username})>[];
    for (final doc in snapshot.docs) {
      final username = (doc.data()['usename_vie'] ?? '').toString().trim();
      if (username.toLowerCase().contains(keyword)) {
        matches.add((userId: doc.id, username: username));
      }
    }
    matches.sort((a, b) => a.username.compareTo(b.username));
    return matches;
  }

  Stream<List<CommunityPostModel>> watchPostsByUserId(String userId) {
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

  Future<List<CommunityPostModel>> searchPostsByContent(String query) async {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return const [];
    }

    final snapshot = await _posts.orderBy('created_at', descending: true).get();
    return snapshot.docs
        .map(CommunityPostModel.fromFirestore)
        .where((post) => post.content.toLowerCase().contains(keyword))
        .toList();
  }

  Future<void> deletePost(String postId) async {
    if (postId.trim().isEmpty) {
      throw Exception('Không xác định được bài đăng cần xóa.');
    }
    await _posts.doc(postId).delete();
  }

  Stream<CommunityAnnouncementModel?> watchAnnouncement() {
    return _announcementRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return CommunityAnnouncementModel.fromFirestore(snapshot);
    });
  }

  Future<void> saveAnnouncement(String content) async {
    final cleaned = content.trim();
    if (cleaned.isEmpty) {
      throw Exception('Nội dung thông báo không được để trống.');
    }

    await _announcementRef.set({
      'content': cleaned,
      'is_active': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearAnnouncement() async {
    await _announcementRef.set({
      'content': '',
      'is_active': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
