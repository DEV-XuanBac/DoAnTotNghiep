import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/providers/post_provider.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_avatar.dart';
import 'package:provider/provider.dart';

class CommunityCreatePostDialog extends StatefulWidget {
  const CommunityCreatePostDialog({super.key});

  @override
  State<CommunityCreatePostDialog> createState() =>
      _CommunityCreatePostDialogState();
}

class _CommunityCreatePostDialogState extends State<CommunityCreatePostDialog> {
  final TextEditingController _composerController = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.read<PostProvider>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<Map<String, String>>(
              stream: postProvider.watchCurrentUserProfile(),
              builder: (context, snapshot) {
                final profile = snapshot.data ?? const {};
                final displayName =
                    (profile['name'] ?? 'Người dùng').trim().isEmpty
                    ? 'Người dùng'
                    : (profile['name'] ?? 'Người dùng').trim();
                final avatar = (profile['avatar'] ?? '').trim();
                return Row(
                  children: [
                    CommunityAvatar(avatar: avatar, size: 52),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: _composerController,
              enabled: !_posting,
              maxLines: 5,
              minLines: 5,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung...',
                hintStyle: TextStyle(
                  color: AppColors.secondaryText,
                  fontStyle: FontStyle.italic,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: BorderSide(
                    color: AppColors.borderFocus,
                    width: 1.1.w,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _posting
                      ? null
                      : () => Navigator.pop(context, false),
                  child: Text(
                    'Quay lại',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                TextButton(
                  onPressed: _posting
                      ? null
                      : () => setState(() => _composerController.clear()),
                  child: Text(
                    'Xóa',
                    style: TextStyle(
                      color: AppColors.errorText,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _posting
                      ? null
                      : () async {
                          final content = _composerController.text.trim();
                          if (content.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hãy nhập nội dung bài đăng.'),
                              ),
                            );
                            return;
                          }
                          setState(() => _posting = true);
                          try {
                            await postProvider.createPost(content);
                            if (!mounted) return;
                            Navigator.pop(context, true);
                          } catch (error) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _posting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundLight,
                    foregroundColor: AppColors.primaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      side: BorderSide(
                        color: AppColors.borderDefault,
                        width: 1.w,
                      ),
                    ),
                  ),
                  child: _posting
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: AppColors.blueDarkText,
                          ),
                        )
                      : const Text('Đăng bài'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
