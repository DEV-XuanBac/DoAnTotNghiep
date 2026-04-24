import 'package:hanziilearnapp/app/models/community_comment_model.dart';

String formatCommunityTimeAgo(DateTime? dateTime) {
  if (dateTime == null) {
    return 'Vừa xong';
  }
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 1) {
    return 'Vừa xong';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} phút trước';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours} giờ trước';
  }
  return '${diff.inDays} ngày trước';
}

List<({CommunityCommentModel comment, int depth})> buildCommunityCommentThread(
  List<CommunityCommentModel> comments,
) {
  final byId = <String, CommunityCommentModel>{
    for (final comment in comments) comment.commentId: comment,
  };
  final children = <String, List<CommunityCommentModel>>{};
  final roots = <CommunityCommentModel>[];

  for (final comment in comments) {
    final parentId = comment.parentCommentId.trim();
    if (parentId.isEmpty || !byId.containsKey(parentId)) {
      roots.add(comment);
    } else {
      children.putIfAbsent(parentId, () => <CommunityCommentModel>[]).add(comment);
    }
  }

  int compareByTime(CommunityCommentModel a, CommunityCommentModel b) {
    final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
    final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
    return at.compareTo(bt);
  }

  roots.sort(compareByTime);
  for (final list in children.values) {
    list.sort(compareByTime);
  }

  final output = <({CommunityCommentModel comment, int depth})>[];

  void visit(CommunityCommentModel node, int depth) {
    output.add((comment: node, depth: depth));
    for (final child in children[node.commentId] ?? const <CommunityCommentModel>[]) {
      visit(child, depth + 1);
    }
  }

  for (final root in roots) {
    visit(root, 0);
  }

  return output;
}
