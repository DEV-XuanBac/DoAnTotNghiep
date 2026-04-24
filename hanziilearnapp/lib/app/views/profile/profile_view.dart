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
  late final _InlineNameEditor _vieEditor = _InlineNameEditor(
    fieldKey: 'usename_vie',
    label: 'Họ tên',
    placeholder: 'Nhập họ tên tiếng Việt',
  );
  late final _InlineNameEditor _cnEditor = _InlineNameEditor(
    fieldKey: 'usename_cn',
    label: '姓名',
    placeholder: '请输入中文姓名',
  );
  bool _isUploadingAvatar = false;

  String _formatDateTime(dynamic value) {
    if (value is! Timestamp) {
      return '--/--/----';
    }
    final dt = value.toDate();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  String _formatDurationFromMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours <= 0) {
      return '$minutes phút';
    }
    return '$hours giờ $minutes phút';
  }

  int _readIntValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  int _extractCompletedExamCount(Map<String, dynamic> profile) {
    final directCount = _readIntValue(profile['hsk_exam_completed_count']);
    if (directCount > 0) return directCount;
    final completedIds = profile['hsk_exam_completed_ids'];
    if (completedIds is List) {
      return completedIds.length;
    }
    return 0;
  }

  int _extractLoginDays(Map<String, dynamic> profile) {
    final loginDates = profile['login_dates'];
    if (loginDates is List) {
      return loginDates.length;
    }
    return 0;
  }

  int _extractOnlineMinutes(Map<String, dynamic> profile) {
    return _readIntValue(profile['total_online_minutes']);
  }

  @override
  void dispose() {
    _vieEditor.dispose();
    _cnEditor.dispose();
    super.dispose();
  }

  void _syncEditorValue(_InlineNameEditor editor, String serverValue) {
    if (editor.focusNode.hasFocus || editor.isSaving) return;
    if (editor.initialValue == serverValue) return;
    editor.initialValue = serverValue;
    editor.controller.text = serverValue;
  }

  bool _hasChanged(_InlineNameEditor editor) {
    return editor.controller.text.trim() != editor.initialValue.trim();
  }

  Future<void> _saveInlineName({
    required String userId,
    required _InlineNameEditor editor,
  }) async {
    final value = editor.controller.text.trim();
    if (value.isEmpty) return;

    setState(() => editor.isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        editor.fieldKey: value,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => editor.initialValue = value);
      editor.focusNode.unfocus();
    } finally {
      if (mounted) {
        setState(() => editor.isSaving = false);
      }
    }
  }

  Future<void> _onAvatarTap(String userId) async {
    if (userId.isEmpty || _isUploadingAvatar) return;
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
                  _pickAvatarAndUpload(userId, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarAndUpload(userId, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAvatarAndUpload(String userId, ImageSource source) async {
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

    setState(() => _isUploadingAvatar = true);
    try {
      final squaredFile = await _cropImageToSquare(File(imagePath));
      final imageUrl = await _uploadImageToCloudinary(squaredFile);
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'avatar': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _syncAvatarToCommunity(userId: userId, avatarUrl: imageUrl);
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
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _syncAvatarToCommunity({
    required String userId,
    required String avatarUrl,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final authoredPosts = await firestore
        .collection('posts')
        .where('user_id', isEqualTo: userId)
        .get();
    await _batchUpdateAvatar(
      references: authoredPosts.docs.map((doc) => doc.reference).toList(),
      avatarUrl: avatarUrl,
    );

    final authoredComments = await firestore
        .collectionGroup('comments')
        .where('user_id', isEqualTo: userId)
        .get();
    await _batchUpdateAvatar(
      references: authoredComments.docs.map((doc) => doc.reference).toList(),
      avatarUrl: avatarUrl,
    );
  }

  Future<void> _batchUpdateAvatar({
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

  Future<String> _uploadImageToCloudinary(File imageFile) async {
    final cloudName = AppConfig.cloudinaryCloudName.trim();
    final uploadPreset = AppConfig.cloudinaryUploadPreset.trim();
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
      final errorMsg = _extractCloudinaryErrorMessage(response.body);
      throw Exception('Upload thất bại (${response.statusCode}): $errorMsg');
    }
    final decoded = jsonDecode(response.body);
    final imageUrl = (decoded['secure_url'] ?? '').toString().trim();
    if (imageUrl.isEmpty) {
      throw Exception('Cloudinary không trả về URL ảnh.');
    }
    return imageUrl;
  }

  String _extractCloudinaryErrorMessage(String responseBody) {
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

  Widget _buildProfileAvatar(String avatarUrl) {
    const fallbackAsset = 'assets/logo/friend_logo.png';
    Widget imageWidget;
    if (avatarUrl.isEmpty) {
      imageWidget = Image.asset(
        fallbackAsset,
        width: 80.w,
        height: 80.w,
        fit: BoxFit.cover,
      );
    } else if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      imageWidget = Image.network(
        avatarUrl,
        width: 80.w,
        height: 80.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          width: 80.w,
          height: 80.w,
          fit: BoxFit.cover,
        ),
      );
    } else {
      imageWidget = Image.asset(
        avatarUrl,
        width: 80.w,
        height: 80.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackAsset,
          width: 80.w,
          height: 80.w,
          fit: BoxFit.cover,
        ),
      );
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDefault, width: 1.w),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50.r),
            child: imageWidget,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: AppColors.blueDarkText,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.whiteText, width: 1.w),
            ),
            child: _isUploadingAvatar
                ? Padding(
                    padding: EdgeInsets.all(5.w),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: AppColors.whiteText,
                    ),
                  )
                : Icon(Icons.camera_alt_rounded, size: 14.sp, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableNameInputRow({
    required _InlineNameEditor editor,
    required String userId,
    required Color textColor,
    required Color borderColor,
  }) {
    final canEdit = userId.isNotEmpty;
    final hasChanged = _hasChanged(editor);
    return Row(
      children: [
        SizedBox(
          width: 60.w,
          child: Text(
            editor.label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: TextField(
            controller: editor.controller,
            focusNode: editor.focusNode,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            readOnly: !canEdit,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (canEdit && hasChanged && !editor.isSaving) {
                _saveInlineName(
                  userId: userId,
                  editor: editor,
                );
              }
            },
            decoration: InputDecoration(
              hintText: editor.placeholder,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 10.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        if (editor.isSaving)
          SizedBox(
            width: 20.w,
            height: 20.h,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        else if (hasChanged)
          IconButton(
            tooltip: 'Xác nhận ${editor.label}',
            onPressed: canEdit
                ? () => _saveInlineName(
                    userId: userId,
                    editor: editor,
                  )
                : null,
            icon: Icon(
              Icons.check_circle_rounded,
              size: 22.sp,
              color: AppColors.greenText,
            ),
          )
        else
          SizedBox(width: 40.w),
      ],
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

  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final user = FirebaseAuth.instance.currentUser;
              final email = (user?.email ?? '').trim();
              final oldPassword = oldPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (email.isEmpty || user == null) {
                setDialogState(() {
                  errorText = 'Không tìm thấy tài khoản đăng nhập.';
                });
                return;
              }
              if (oldPassword.isEmpty || newPassword.isEmpty) {
                setDialogState(() {
                  errorText = 'Vui lòng nhập đầy đủ thông tin.';
                });
                return;
              }
              if (newPassword.length < 6) {
                setDialogState(() {
                  errorText = 'Mật khẩu mới cần ít nhất 6 ký tự.';
                });
                return;
              }
              if (newPassword != confirmPassword) {
                setDialogState(() {
                  errorText = 'Xác nhận mật khẩu mới không khớp.';
                });
                return;
              }
              if (oldPassword == newPassword) {
                setDialogState(() {
                  errorText = 'Mật khẩu mới phải khác mật khẩu cũ.';
                });
                return;
              }

              setDialogState(() {
                isSubmitting = true;
                errorText = null;
              });

              try {
                final credential = EmailAuthProvider.credential(
                  email: email,
                  password: oldPassword,
                );
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đổi mật khẩu thành công.')),
                );
              } on FirebaseAuthException catch (e) {
                setDialogState(() {
                  if (e.code == 'wrong-password' ||
                      e.code == 'invalid-credential') {
                    errorText = 'Mật khẩu cũ không chính xác.';
                  } else if (e.code == 'weak-password') {
                    errorText = 'Mật khẩu mới quá yếu.';
                  } else {
                    errorText = 'Không thể đổi mật khẩu (${e.code}).';
                  }
                });
              } catch (_) {
                setDialogState(() {
                  errorText = 'Không thể đổi mật khẩu. Vui lòng thử lại.';
                });
              } finally {
                setDialogState(() {
                  isSubmitting = false;
                });
              }
            }

            InputDecoration buildInputDecoration(String hintText) {
              return InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 10.h,
                ),
              );
            }

            return AlertDialog(
              title: const Text('Đổi mật khẩu'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    enabled: !isSubmitting,
                    decoration: buildInputDecoration('Mật khẩu cũ'),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    enabled: !isSubmitting,
                    decoration: buildInputDecoration('Mật khẩu mới'),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    enabled: !isSubmitting,
                    decoration: buildInputDecoration('Xác nhận mật khẩu mới'),
                  ),
                  if (errorText != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: AppColors.errorText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
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
          _syncEditorValue(_vieEditor, usernameVie);
          _syncEditorValue(_cnEditor, usernameCn);
          final updatedAt = _formatDateTime(profile['updated_at']);
          final loginDays = _extractLoginDays(profile);
          final onlineMinutes = _extractOnlineMinutes(profile);
          final completedExams = _extractCompletedExamCount(profile);

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
                        onTap: () => _onAvatarTap(user?.uid ?? ''),
                        child: _buildProfileAvatar(avatarUrl),
                      ),
                      SizedBox(height: 15.h),
                      _buildEditableNameInputRow(
                        editor: _vieEditor,
                        userId: user?.uid ?? '',
                        textColor: textColor,
                        borderColor: borderColor,
                      ),
                      SizedBox(height: 10.h),
                      _buildEditableNameInputRow(
                        editor: _cnEditor,
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
                        'Thời gian trực tuyến: ${_formatDurationFromMinutes(onlineMinutes)}',
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
                          onPressed: _showChangePasswordDialog,
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
    required this.fieldKey,
    required this.label,
    required this.placeholder,
  });

  final String fieldKey;
  final String label;
  final String placeholder;
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  String initialValue = '';
  bool isSaving = false;

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}
