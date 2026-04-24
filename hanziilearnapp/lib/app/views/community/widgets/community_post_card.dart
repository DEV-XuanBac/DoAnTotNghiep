import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/community_post_model.dart';
import 'package:hanziilearnapp/app/views/community/community_utils.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_avatar.dart';

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.isManage,
    required this.onToggleLike,
    required this.onOpenComments,
    required this.onDelete,
  });

  final CommunityPostModel post;
  final String currentUserId;
  final bool isManage;
  final Future<void> Function(CommunityPostModel post) onToggleLike;
  final Future<void> Function(CommunityPostModel post) onOpenComments;
  final Future<void> Function(String postId) onDelete;

  @override
  Widget build(BuildContext context) {
    final likedByMe = post.likedBy(currentUserId);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderDefault, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommunityAvatar(avatar: post.userAvatar, size: 34.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName.trim().isEmpty
                          ? 'Người dùng'
                          : post.userName,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formatCommunityTimeAgo(post.createdAt),
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 10.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 10.h),
            child: Text(
              post.content,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 8.h),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderDefault, width: 1.w),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => onToggleLike(post),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 20.sp,
                        color: likedByMe
                            ? AppColors.favourText
                            : AppColors.secondaryText,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${post.likeCount}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 30.w),
                InkWell(
                  onTap: () => onOpenComments(post),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20.sp,
                        color: AppColors.secondaryText,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${post.commentCount}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isManage) ...[
                  const Spacer(),
                  InkWell(
                    onTap: () => onDelete(post.postId),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 2.h,
                        horizontal: 4.w,
                      ),
                      child: Text(
                        'Xóa',
                        style: TextStyle(
                          color: AppColors.errorText,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
