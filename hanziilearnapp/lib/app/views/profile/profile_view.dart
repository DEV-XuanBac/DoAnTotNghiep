import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/config/app_config.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/providers/auth_provider.dart' as app_auth;
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:hanziilearnapp/app/routes/app_routes.dart';
import 'package:hanziilearnapp/app/views/common/in_app_camera_view.dart';
import 'package:hanziilearnapp/app/views/profile/widgets/change_pw_dialog.dart';
import 'package:hanziilearnapp/app/views/profile/widgets/profile_avatar.dart';
import 'package:hanziilearnapp/app/views/profile/widgets/profile_name_row.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileDemoView extends StatefulWidget {
  const ProfileDemoView({super.key});

  @override
  State<ProfileDemoView> createState() => _ProfileDemoViewState();
}

class _ProfileDemoViewState extends State<ProfileDemoView> {
  late final _InlineNameEditor _vieEd = _InlineNameEditor(
    key: 'usename_vie',
    label: 'Họ tên',
    hint: 'Nhập họ tên tiếng Việt',
  );
  late final _InlineNameEditor _cnEd = _InlineNameEditor(
    key: 'usename_cn',
    label: '姓名',
    hint: '请输入中文姓名',
  );
  bool _uploadingAvt = false;

  String _fmtDate(dynamic value) {
    if (value is! Timestamp) {
      return '--/--/----';
    }
    final dt = value.toDate();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  String _fmtMins(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours <= 0) {
      return '$minutes phút';
    }
    return '$hours giờ $minutes phút';
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  int _examDoneCnt(Map<String, dynamic> profile) {
    final directCount = _readInt(profile['hsk_exam_completed_count']);
    if (directCount > 0) return directCount;
    final completedIds = profile['hsk_exam_completed_ids'];
    if (completedIds is List) {
      return completedIds.length;
    }
    return 0;
  }

  int _loginDays(Map<String, dynamic> profile) {
    final loginDates = profile['login_dates'];
    if (loginDates is List) {
      return loginDates.length;
    }
    return 0;
  }

  int _onlineMins(Map<String, dynamic> profile) {
    return _readInt(profile['total_online_minutes']);
  }

  @override
  void dispose() {
    _vieEd.dispose();
    _cnEd.dispose();
    super.dispose();
  }

  void _syncEdVal(_InlineNameEditor ed, String serverValue) {
    if (ed.node.hasFocus || ed.saving) return;
    if (ed.initVal == serverValue) return;
    ed.initVal = serverValue;
    ed.ctrl.text = serverValue;
  }

  bool _isEdChanged(_InlineNameEditor ed) {
    return ed.ctrl.text.trim() != ed.initVal.trim();
  }

  Future<void> _saveName({
    required String userId,
    required _InlineNameEditor ed,
  }) async {
    final value = ed.ctrl.text.trim();
    if (value.isEmpty) return;

    setState(() => ed.saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        ed.key: value,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => ed.initVal = value);
      ed.node.unfocus();
    } finally {
      if (mounted) {
        setState(() => ed.saving = false);
      }
    }
  }

  Future<void> _onAvtTap(String userId) async {
    if (userId.isEmpty || _uploadingAvt) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvtAndUpload(userId, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvtAndUpload(userId, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAvtAndUpload(String userId, ImageSource source) async {
    String? imagePath;
    if (source == ImageSource.camera) {
      final capturedPath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const InAppCameraView()),
      );
      if (capturedPath == null || capturedPath.trim().isEmpty) {
        return;
      }
      imagePath = capturedPath;
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (picked == null) return;
      imagePath = picked.path;
    }

    setState(() => _uploadingAvt = true);
    try {
      final squaredFile = await _cropImageToSquare(File(imagePath));
      final imageUrl = await _uploadCloudinary(squaredFile);
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'avatar': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _syncAvtToCommunity(userId: userId, avatarUrl: imageUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật ảnh đại diện: ${error.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingAvt = false);
      }
    }
  }

  Future<void> _syncAvtToCommunity({
    required String userId,
    required String avatarUrl,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final authoredPosts = await firestore
        .collection('posts')
        .where('user_id', isEqualTo: userId)
        .get();
    await _batchUpdateAvt(
      references: authoredPosts.docs.map((doc) => doc.reference).toList(),
      avatarUrl: avatarUrl,
    );

    final authoredComments = await firestore
        .collectionGroup('comments')
        .where('user_id', isEqualTo: userId)
        .get();
    await _batchUpdateAvt(
      references: authoredComments.docs.map((doc) => doc.reference).toList(),
      avatarUrl: avatarUrl,
    );
  }

  Future<void> _batchUpdateAvt({
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

  Future<File> _cropImageToSquare(File sourceFile) async {
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

  Future<String> _uploadCloudinary(File imageFile) async {
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
      final errorMsg = _parseCloudErr(response.body);
      throw Exception('Upload thất bại (${response.statusCode}): $errorMsg');
    }
    final decoded = jsonDecode(response.body);
    final imageUrl = (decoded['secure_url'] ?? '').toString().trim();
    if (imageUrl.isEmpty) {
      throw Exception('Cloudinary không trả về URL ảnh.');
    }
    return imageUrl;
  }

  String _parseCloudErr(String responseBody) {
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

  Widget _buildNameRow({
    required _InlineNameEditor ed,
    required String userId,
    required Color textColor,
    required Color borderColor,
  }) {
    final canEdit = userId.isNotEmpty;
    final changed = _isEdChanged(ed);
    return ProfileNameRow(
      label: ed.label,
      hint: ed.hint,
      ctrl: ed.ctrl,
      node: ed.node,
      saving: ed.saving,
      changed: changed,
      canEdit: canEdit,
      textColor: textColor,
      borderColor: borderColor,
      onChanged: (_) => setState(() {}),
      onSubmit: (_) {
        if (canEdit && changed && !ed.saving) {
          _saveName(userId: userId, ed: ed);
        }
      },
      onSaveTap: () => _saveName(userId: userId, ed: ed),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<app_auth.AuthProvider>().signOut();
    if (!mounted || !context.mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.main,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = AppColors.backgroundLight;
    final cardColor = AppColors.backgroundWhite;
    final textColor = AppColors.primaryText;
    final subTextColor = AppColors.secondaryText;
    final borderColor = AppColors.borderDefault;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text('Hồ sơ cá nhân', style: TextStyle(color: textColor)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: user == null
            ? null
            : FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
        builder: (context, snapshot) {
          final profile = snapshot.data?.data() ?? <String, dynamic>{};
          final usernameVie = (profile['usename_vie'] ?? '').toString().trim();
          final usernameCn = (profile['usename_cn'] ?? '').toString().trim();
          final avatarUrl = (profile['avatar'] ?? '').toString().trim();
          _syncEdVal(_vieEd, usernameVie);
          _syncEdVal(_cnEd, usernameCn);
          final updatedAt = _fmtDate(profile['updated_at']);
          final loginDays = _loginDays(profile);
          final onlineMinutes = _onlineMins(profile);
          final completedExams = _examDoneCnt(profile);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _onAvtTap(user?.uid ?? ''),
                        child: ProfileAvatar(url: avatarUrl, uploading: _uploadingAvt),
                      ),
                      SizedBox(height: 15.h),
                      _buildNameRow(
                        ed: _vieEd,
                        userId: user?.uid ?? '',
                        textColor: textColor,
                        borderColor: borderColor,
                      ),
                      SizedBox(height: 10.h),
                      _buildNameRow(
                        ed: _cnEd,
                        userId: user?.uid ?? '',
                        textColor: textColor,
                        borderColor: borderColor,
                      ),
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
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.borderDefault,
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          'Cập nhật lần cuối: $updatedAt',
                          style: TextStyle(
                            color: subTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
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
                        'Thời gian trực tuyến: ${_fmtMins(onlineMinutes)}',
                        style: TextStyle(fontSize: 14.sp, color: textColor),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Số bài thi đã hoàn thành: $completedExams bài',
                        style: TextStyle(fontSize: 14.sp, color: textColor),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Chuyển đổi chế độ sáng/tối
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.backgroundGradientStart,
                              AppColors.backgroundGradientEnd,
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
                                  color: isDark
                                      ? Colors.amberAccent
                                      : Colors.orange,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  isDark ? 'Chế độ tối' : 'Chế độ sáng',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: isDark,
                              onChanged: (value) => context
                                  .read<ThemeProvider>()
                                  .setDarkMode(value),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                      SizedBox(
                        width: 190.w,
                        height: 45.h,
                        child: ElevatedButton.icon(
                          onPressed: () => showChangePwDlg(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blueDarkText.withValues(
                              alpha: 0.9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            elevation: 2,
                          ),
                          icon: Icon(
                            Icons.lock_reset_rounded,
                            color: AppColors.whiteText,
                            size: 20.sp,
                          ),
                          label: Text(
                            'Đổi mật khẩu',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.whiteText,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // Đăng xuất
                      SizedBox(
                        width: 190.w,
                        height: 45.h,
                        child: ElevatedButton(
                          onPressed: () => _logout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorText.withValues(
                              alpha: 0.78,
                            ),
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
                              color: AppColors.whiteText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InlineNameEditor {
  _InlineNameEditor({
    required this.key,
    required this.label,
    required this.hint,
  });

  final String key;
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
