import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/router/app_router.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/datasource/services/vocabulary_reminder_service.dart';
import 'package:hanziilearnapp/app/providers/auth_provider.dart' as app_auth;
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:hanziilearnapp/app/views/profile/profile_screen_widgets.dart';
import 'package:hanziilearnapp/app/views/profile/widgets/change_pw_dialog.dart';
import 'package:hanziilearnapp/app/views/profile/widgets/profile_name_row.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileDemoView extends StatefulWidget {
  const ProfileDemoView({super.key});

  @override
  State<ProfileDemoView> createState() => _ProfileDemoViewState();
}

class _ProfileDemoViewState extends State<ProfileDemoView> {
  late final ProfileDocFieldEditor _vieEd = ProfileDocFieldEditor(
    docField: 'usename_vie',
    label: 'Họ tên',
    hint: 'Nhập họ tên tiếng Việt',
  );
  late final ProfileDocFieldEditor _cnEd = ProfileDocFieldEditor(
    docField: 'usename_cn',
    label: '姓名',
    hint: '请输入中文姓名',
  );
  bool _uploadingAvt = false;
  bool _vocabReminderEnabled = false;
  bool _vocabReminderLoading = false;
  bool _vocabReminderPrefsLoaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadVocabReminderPref());
  }

  Future<void> _loadVocabReminderPref() async {
    final v = await VocabularyReminderService.isEnabled();
    if (!mounted) return;
    setState(() {
      _vocabReminderEnabled = v;
      _vocabReminderPrefsLoaded = true;
    });
  }

  Future<void> _onVocabReminderToggled(
    BuildContext context,
    String userId,
    bool enabled,
  ) async {
    setState(() => _vocabReminderLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (enabled) {
        await VocabularyReminderService.enableForUser(userId);
      } else {
        await VocabularyReminderService.disable();
      }
      if (!mounted) return;
      setState(() => _vocabReminderEnabled = enabled);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Đã bật thông báo từ yêu thích (mỗi 3 giờ).'
                : 'Đã tắt thông báo từ yêu thích.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể cập nhật thông báo: $e')),
      );
    } finally {
      if (mounted) setState(() => _vocabReminderLoading = false);
    }
  }

  @override
  void dispose() {
    _vieEd.dispose();
    _cnEd.dispose();
    super.dispose();
  }

  void _syncEdVal(ProfileDocFieldEditor ed, String serverValue) {
    if (ed.node.hasFocus || ed.saving) return;
    if (ed.initVal == serverValue) return;
    ed.initVal = serverValue;
    ed.ctrl.text = serverValue;
  }

  bool _isEdChanged(ProfileDocFieldEditor ed) {
    return ed.ctrl.text.trim() != ed.initVal.trim();
  }

  Future<void> _saveName({
    required String userId,
    required ProfileDocFieldEditor ed,
  }) async {
    final value = ed.ctrl.text.trim();
    if (value.isEmpty) return;

    setState(() => ed.saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        ed.docField: value,
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
    final messenger = ScaffoldMessenger.of(context);
    String? imagePath;
    if (source == ImageSource.camera) {
      final capturedPath = await AppRouter.pushCamera(context);
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
      final squaredFile = await ProfileAvatarUpload.cropImageToSquare(
        File(imagePath),
      );
      final imageUrl = await ProfileAvatarUpload.uploadCloudinary(squaredFile);
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'avatar': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await ProfileAvatarUpload.syncAvatarToCommunity(
        userId: userId,
        avatarUrl: imageUrl,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật ảnh đại diện: ${error.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingAvt = false);
      }
    }
  }

  Widget _buildNameRow({
    required ProfileDocFieldEditor ed,
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
    await VocabularyReminderService.disableOnLogout();
    if (!context.mounted) return;
    await context.read<app_auth.AuthProvider>().signOut();
    if (!mounted || !context.mounted) {
      return;
    }
    unawaited(AppRouter.goToMainTab(context));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = context.select<ThemeProvider, bool>((p) => p.isDarkMode);
    final bgColor = context.palette.backgroundLight;
    final cardColor = context.palette.backgroundWhite;
    final textColor = context.palette.primaryText;
    final subTextColor = context.palette.secondaryText;
    final borderColor = context.palette.borderDefault;

    return SafeArea(
      top: false,
      child: Scaffold(
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
            final usernameVie = (profile['usename_vie'] ?? '')
                .toString()
                .trim();
            final usernameCn = (profile['usename_cn'] ?? '').toString().trim();
            final avatarUrl = (profile['avatar'] ?? '').toString().trim();
            _syncEdVal(_vieEd, usernameVie);
            _syncEdVal(_cnEd, usernameCn);
            final updatedAt = profileFmtDate(profile['updated_at']);
            final loginDays = profileLoginDays(profile);
            final onlineMinutes = profileOnlineMins(profile);
            final completedExams = profileExamDoneCnt(profile);

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileIdentitySection(
                    user: user,
                    avatarUrl: avatarUrl,
                    uploading: _uploadingAvt,
                    vieNameRow: _buildNameRow(
                      ed: _vieEd,
                      userId: user?.uid ?? '',
                      textColor: textColor,
                      borderColor: borderColor,
                    ),
                    cnNameRow: _buildNameRow(
                      ed: _cnEd,
                      userId: user?.uid ?? '',
                      textColor: textColor,
                      borderColor: borderColor,
                    ),
                    updatedAtLabel: updatedAt,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    onAvatarTap: () => _onAvtTap(user?.uid ?? ''),
                  ),
                  SizedBox(height: 20.h),
                  ProfileStatsSection(
                    loginDays: loginDays,
                    onlineMinutesLabel: profileFmtMins(onlineMinutes),
                    completedExams: completedExams,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  SizedBox(height: 20.h),
                  ProfileSettingsSection(
                    isDark: isDark,
                    vocabReminderUserId: user?.uid,
                    vocabReminderEnabled: _vocabReminderEnabled,
                    vocabReminderPrefsLoaded: _vocabReminderPrefsLoaded,
                    vocabReminderLoading: _vocabReminderLoading,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    onVocabReminderChanged: user == null
                        ? null
                        : (enabled) => _onVocabReminderToggled(
                              context,
                              user.uid,
                              enabled,
                            ),
                    onChangePassword: () => showChangePwDlg(context),
                    onLogout: () => _logout(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
