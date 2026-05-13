import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/core/constants/community_constants.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.palette.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
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
                    CommunityAvatar(avatar: avatar, size: 46.w),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: context.palette.primaryText,
                          fontSize: 16.sp,
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
              style: TextStyle(color: context.palette.primaryText, fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: 'Nhập nội dung...',
                hintStyle: TextStyle(
                  color: context.palette.secondaryText,
                  fontStyle: FontStyle.italic,
                  fontSize: 12.sp,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: context.palette.borderFocus,
                    width: 1.w,
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
                      color: context.palette.primaryText,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                TextButton(
                  onPressed: _posting
                      ? null
                      : () => setState(_composerController.clear),
                  child: Text(
                    'Xóa',
                    style: TextStyle(
                      color: context.palette.errorText,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _posting
                      ? null
                      : () async {
                          final content = _composerController.text.trim();
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          if (content.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Hãy nhập nội dung bài đăng.'),
                              ),
                            );
                            return;
                          }
                          setState(() => _posting = true);
                          try {
                            await postProvider.createPost(content);
                            if (!mounted) {
                              return;
                            }
                            navigator.pop(true);
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _posting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.backgroundLight,
                    foregroundColor: context.palette.primaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      side: BorderSide(
                        color: context.palette.borderDefault,
                        width: 1.w,
                      ),
                    ),
                  ),
                  child: _posting
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: context.palette.blueDarkText,
                          ),
                        )
                      : Text(
                          CommunityConstants.createPost,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
