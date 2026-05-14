import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/config/app_config.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:hanziilearnapp/app/views/profile/widgets/profile_avatar.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

// --- Hiển thị / đọc profile từ Firestore ---

String profileFmtDate(dynamic value) {
  if (value is! Timestamp) {
    return '--/--/----';
  }
  final dt = value.toDate();
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year.toString().padLeft(4, '0');
  return '$day/$month/$year';
}

String profileFmtMins(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours <= 0) {
    return '$minutes phút';
  }
  return '$hours giờ $minutes phút';
}

int profileReadInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

int profileExamDoneCnt(Map<String, dynamic> profile) {
  final directCount = profileReadInt(profile['hsk_exam_completed_count']);
  if (directCount > 0) return directCount;
  final completedIds = profile['hsk_exam_completed_ids'];
  if (completedIds is List) {
    return completedIds.length;
  }
  return 0;
}

int profileLoginDays(Map<String, dynamic> profile) {
  final loginDates = profile['login_dates'];
  if (loginDates is List) {
    return loginDates.length;
  }
  return 0;
}

int profileOnlineMins(Map<String, dynamic> profile) {
  return profileReadInt(profile['total_online_minutes']);
}

// --- Upload avatar (Cloudinary + đồng bộ cộng đồng) ---

abstract final class ProfileAvatarUpload {
  static Future<File> cropImageToSquare(File sourceFile) async {
    final bytes = await sourceFile.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception('Ảnh không hợp lệ.');
    }

    final side = math.min(original.width, original.height);
    final offsetX = (original.width - side) ~/ 2;
    final offsetY = (original.height - side) ~/ 2;
    final square = img.copyCrop(
      original,
      x: offsetX,
      y: offsetY,
      width: side,
      height: side,
    );
    final resized = img.copyResize(square, width: 720, height: 720);
    final outputBytes = img.encodeJpg(resized, quality: 88);
    final outputPath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(outputBytes, flush: true);
    return outputFile;
  }

  static Future<String> uploadCloudinary(File imageFile) async {
    final cloudName = AppConfig.cloudName.trim();
    final uploadPreset = AppConfig.uploadPreset.trim();
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception(
        'Thiếu cấu hình Cloudinary. Cập nhật cloudName/uploadPreset trong AppConfig.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMsg = parseCloudErr(response.body);
      throw Exception('Upload thất bại (${response.statusCode}): $errorMsg');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Cloudinary trả về dữ liệu không hợp lệ.');
    }
    final imageUrl = (decoded['secure_url'] ?? '').toString().trim();
    if (imageUrl.isEmpty) {
      throw Exception('Cloudinary không trả về URL ảnh.');
    }
    return imageUrl;
  }

  static String parseCloudErr(String responseBody) {
    try {
      final parsed = jsonDecode(responseBody);
      if (parsed is Map<String, dynamic>) {
        final err = parsed['error'];
        if (err is Map<String, dynamic>) {
          final msg = (err['message'] ?? '').toString().trim();
          if (msg.isNotEmpty) return msg;
        }
      }
    } catch (_) {}
    return 'Không rõ nguyên nhân';
  }

  static Future<void> syncAvatarToCommunity({
    required String userId,
    required String avatarUrl,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final authoredPosts = await firestore
        .collection('posts')
        .where('user_id', isEqualTo: userId)
        .get();
    await batchUpdateAvatarOnRefs(
      references: authoredPosts.docs.map((doc) => doc.reference).toList(),
      avatarUrl: avatarUrl,
    );

    final authoredComments = await firestore
        .collectionGroup('comments')
        .where('user_id', isEqualTo: userId)
        .get();
    await batchUpdateAvatarOnRefs(
      references: authoredComments.docs.map((doc) => doc.reference).toList(),
      avatarUrl: avatarUrl,
    );
  }

  static Future<void> batchUpdateAvatarOnRefs({
    required List<DocumentReference<Map<String, dynamic>>> references,
    required String avatarUrl,
  }) async {
    if (references.isEmpty) return;
    for (var i = 0; i < references.length; i += 400) {
      final end = (i + 400 > references.length) ? references.length : i + 400;
      final chunk = references.sublist(i, end);
      final batch = FirebaseFirestore.instance.batch();
      for (final ref in chunk) {
        batch.update(ref, {'user_avatar': avatarUrl});
      }
      await batch.commit();
    }
  }
}

// --- Trạng thái chỉnh tên trên Firestore ---

class ProfileDocFieldEditor {
  ProfileDocFieldEditor({
    required this.docField,
    required this.label,
    required this.hint,
  });

  final String docField;
  final String label;
  final String hint;
  final TextEditingController ctrl = TextEditingController();
  final FocusNode node = FocusNode();
  String initVal = '';
  bool saving = false;

  void dispose() {
    ctrl.dispose();
    node.dispose();
  }
}

// --- Các khối UI màn hồ sơ ---

class ProfileIdentitySection extends StatelessWidget {
  const ProfileIdentitySection({
    super.key,
    required this.user,
    required this.avatarUrl,
    required this.uploading,
    required this.vieNameRow,
    required this.cnNameRow,
    required this.updatedAtLabel,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.onAvatarTap,
  });

  final User? user;
  final String avatarUrl;
  final bool uploading;
  final Widget vieNameRow;
  final Widget cnNameRow;
  final String updatedAtLabel;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: ProfileAvatar(
              url: avatarUrl,
              uploading: uploading,
            ),
          ),
          SizedBox(height: 15.h),
          vieNameRow,
          SizedBox(height: 10.h),
          cnNameRow,
          SizedBox(height: 10.h),
          Text(
            'Email: ${user?.email ?? 'Chưa đăng nhập'}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 10.h,
            ),
            decoration: BoxDecoration(
              color: context.palette.backgroundLight,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.palette.borderDefault,
                width: 1.w,
              ),
            ),
            child: Text(
              'Cập nhật lần cuối: $updatedAtLabel',
              style: TextStyle(
                color: subTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({
    super.key,
    required this.loginDays,
    required this.onlineMinutesLabel,
    required this.completedExams,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
  });

  final int loginDays;
  final String onlineMinutesLabel;
  final int completedExams;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số ngày đăng nhập: $loginDays ngày',
            style: TextStyle(fontSize: 14.sp, color: textColor),
          ),
          SizedBox(height: 12.h),
          Text(
            'Thời gian trực tuyến: $onlineMinutesLabel',
            style: TextStyle(fontSize: 14.sp, color: textColor),
          ),
          SizedBox(height: 12.h),
          Text(
            'Số bài thi đã hoàn thành: $completedExams bài',
            style: TextStyle(fontSize: 14.sp, color: textColor),
          ),
        ],
      ),
    );
  }
}

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    super.key,
    required this.isDark,
    required this.vocabReminderUserId,
    required this.vocabReminderEnabled,
    required this.vocabReminderPrefsLoaded,
    required this.vocabReminderLoading,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.onVocabReminderChanged,
    required this.onChangePassword,
    required this.onLogout,
  });

  final bool isDark;
  final String? vocabReminderUserId;
  final bool vocabReminderEnabled;
  final bool vocabReminderPrefsLoaded;
  final bool vocabReminderLoading;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final ValueChanged<bool>? onVocabReminderChanged;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final showVocab =
        vocabReminderUserId != null && onVocabReminderChanged != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.palette.backgroundGradientStart,
                  context.palette.backgroundGradientEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.wb_sunny_rounded,
                      color: isDark ? Colors.amberAccent : Colors.orange,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      isDark ? 'Chế độ tối' : 'Chế độ sáng',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: context.palette.primaryText,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isDark,
                  onChanged: (value) =>
                      context.read<ThemeProvider>().setDarkMode(value),
                ),
              ],
            ),
          ),
          if (showVocab) ...[
            SizedBox(height: 14.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: context.palette.backgroundLight,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: context.palette.borderDefault,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: context.palette.blueDarkText,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Nhắc nhở ôn tập',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (!vocabReminderPrefsLoaded)
                    SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.palette.blueDarkText,
                      ),
                    )
                  else
                    Switch(
                      value: vocabReminderEnabled,
                      onChanged: vocabReminderLoading
                          ? null
                          : onVocabReminderChanged,
                    ),
                ],
              ),
            ),
          ],
          SizedBox(height: 14.h),
          SizedBox(
            width: 190.w,
            height: 45.h,
            child: ElevatedButton.icon(
              onPressed: onChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    context.palette.blueDarkText.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 2,
              ),
              icon: Icon(
                Icons.lock_reset_rounded,
                color: context.palette.whiteText,
                size: 20.sp,
              ),
              label: Text(
                'Đổi mật khẩu',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: context.palette.whiteText,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: 190.w,
            height: 45.h,
            child: ElevatedButton(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    context.palette.errorText.withValues(alpha: 0.78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 2,
              ),
              child: Text(
                'Đăng xuất',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.palette.whiteText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
