import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/community_post_model.dart';
import 'package:hanziilearnapp/app/providers/post_provider.dart';
import 'package:hanziilearnapp/app/views/community/community_tab_type.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_avatar.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_comment_sheet.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_create_post_dialog.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_post_card.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_tab_selector.dart';
import 'package:provider/provider.dart';

class CommunityView extends StatefulWidget {
  const CommunityView({super.key});

  @override
  State<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView> {
  CommunityTabType _currentTab = CommunityTabType.all;

  Future<void> _openCreatePostDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const CommunityCreatePostDialog(),
    );
    if (created == true && mounted) {
      setState(() => _currentTab = CommunityTabType.all);
    }
  }

  Future<void> _openCommentSheet(CommunityPostModel post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => CommunityCommentSheet(post: post),
    );
  }

  Future<void> _toggleLike(CommunityPostModel post) async {
    try {
      await context.read<PostProvider>().toggleLike(post);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await context.read<PostProvider>().deletePost(postId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Stream<List<CommunityPostModel>> _postsByCurrentTab() {
    final provider = context.read<PostProvider>();
    final userId = provider.currentUserId;
    switch (_currentTab) {
      case CommunityTabType.all:
        return provider.watchAllPosts();
      case CommunityTabType.interacted:
        if (userId == null || userId.isEmpty) {
          return Stream<List<CommunityPostModel>>.value(const []);
        }
        return provider.watchInteractedPosts(userId);
      case CommunityTabType.manage:
        if (userId == null || userId.isEmpty) {
          return Stream<List<CommunityPostModel>>.value(const []);
        }
        return provider.watchManagedPosts(userId);
    }
  }

  Widget _buildComposer() {
    return StreamBuilder<Map<String, String>>(
      stream: context.read<PostProvider>().watchCurrentUserProfile(),
      builder: (context, snapshot) {
        final avatar = (snapshot.data?['avatar'] ?? '').trim();
        return Row(
          children: [
            CommunityAvatar(avatar: avatar, size: 38),
            SizedBox(width: 8.w),
            Expanded(
              child: InkWell(
                onTap: _openCreatePostDialog,
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 11.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.borderDefault,
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    'Bạn đang thắc mắc điều gì?',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostList() {
    return StreamBuilder<List<CommunityPostModel>>(
      stream: _postsByCurrentTab(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Không tải được bài viết. Vui lòng thử lại.',
              style: TextStyle(
                color: AppColors.errorText,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data ?? const <CommunityPostModel>[];
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'Chưa có bài viết nào',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        final currentUserId = context.read<PostProvider>().currentUserId ?? '';
        final isManage = _currentTab == CommunityTabType.manage;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => CommunityPostCard(
            post: posts[index],
            currentUserId: currentUserId,
            isManage: isManage,
            onToggleLike: _toggleLike,
            onOpenComments: _openCommentSheet,
            onDelete: _deletePost,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cộng đồng Hanzii',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 14.h),
              _buildComposer(),
              SizedBox(height: 10.h),
              CommunityTabSelector(
                currentTab: _currentTab,
                onChanged: (tab) => setState(() => _currentTab = tab),
              ),
              SizedBox(height: 12.h),
              Expanded(child: _buildPostList()),
            ],
          ),
        ),
      ),
    );
  }
}
