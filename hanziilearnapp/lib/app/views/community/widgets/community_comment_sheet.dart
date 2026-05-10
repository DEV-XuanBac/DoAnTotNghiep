import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/core/constants/community_constants.dart';
import 'package:hanziilearnapp/app/models/community_comment_model.dart';
import 'package:hanziilearnapp/app/models/community_post_model.dart';
import 'package:hanziilearnapp/app/providers/post_provider.dart';
import 'package:hanziilearnapp/app/views/community/community_utils.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_avatar.dart';
import 'package:provider/provider.dart';

class CommunityCommentSheet extends StatefulWidget {
  const CommunityCommentSheet({super.key, required this.post});

  final CommunityPostModel post;

  @override
  State<CommunityCommentSheet> createState() => _CommunityCommentSheetState();
}

class _CommunityCommentSheetState extends State<CommunityCommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  CommunityCommentModel? _replyTarget;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.read<PostProvider>();
    final currentUserId = postProvider.currentUserId ?? '';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14.w,
          10.h,
          14.w,
          MediaQuery.of(context).viewInsets.bottom + 10.h,
        ),
        child: SizedBox(
          height: 460.h,
          child: Column(
            children: [
              Container(
                width: 50.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                CommunityConstants.cmtTitle,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: StreamBuilder<List<CommunityCommentModel>>(
                  stream: postProvider.watchComments(widget.post.postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Không tải được bình luận',
                          style: TextStyle(
                            color: AppColors.errorText,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }
                    final comments =
                        snapshot.data ?? const <CommunityCommentModel>[];
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          CommunityConstants.noComments,
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }
                    final threadedComments = buildCommunityCommentThread(
                      comments,
                    );
                    return ListView.separated(
                      itemCount: threadedComments.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final threadItem = threadedComments[index];
                        final comment = threadItem.comment;
                        final depth = threadItem.depth;
                        final canReply = currentUserId.isNotEmpty && depth < 2;
                        final leftInset = (depth * 18).clamp(0, 54).toDouble();
                        return Padding(
                          padding: EdgeInsets.only(left: leftInset.w),
                          child: Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight.withValues(
                                alpha: depth == 0 ? 0.45 : 0.32,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                              border: depth > 0
                                  ? Border(
                                      left: BorderSide(
                                        color: AppColors.borderDefault,
                                        width: 2.w,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CommunityAvatar(
                                      avatar: comment.userAvatar,
                                      size: 30.w,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        comment.userName.trim().isEmpty
                                            ? 'Người dùng'
                                            : comment.userName,
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatCommunityTimeAgo(comment.createdAt),
                                      style: TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                if (comment.isReply &&
                                    comment.parentUserName.trim().isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 4.h),
                                    child: Text(
                                      '${CommunityConstants.reply} ${comment.parentUserName}:',
                                      style: TextStyle(
                                        color: AppColors.blueDarkText,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                Text(
                                  comment.content,
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                if (canReply)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _replyTarget = comment;
                                        });
                                      },
                                      child: Text(
                                        CommunityConstants.reply,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: AppColors.blueDarkText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (currentUserId.isNotEmpty && depth >= 2)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Đạt giới hạn trả lời',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: AppColors.secondaryText,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_replyTarget != null)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 8.h, bottom: 6.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Đang trả lời ${_replyTarget!.userName}',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _replyTarget = null),
                        child: Icon(
                          Icons.close,
                          size: 16.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40.h,
                      child: TextField(
                        controller: _commentController,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: _replyTarget == null
                              ? CommunityConstants.cmtHint
                              : CommunityConstants.replyHint,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 10.h,
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppColors.borderDefault,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppColors.borderDefault,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  SizedBox(
                    height: 40.h,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await postProvider.addComment(
                            widget.post.postId,
                            _commentController.text,
                            parentCommentId: _replyTarget?.commentId ?? '',
                            parentUserId: _replyTarget?.userId ?? '',
                            parentUserName: _replyTarget?.userName ?? '',
                          );
                          _commentController.clear();
                          setState(() => _replyTarget = null);
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Gửi',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
