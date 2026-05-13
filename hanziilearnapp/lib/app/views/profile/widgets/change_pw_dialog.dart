import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';

Future<void> showChangePwDlg(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dlgCtx) => _ChangePasswordDialog(hostContext: context),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.hostContext});

  /// Context bên dưới dialog (có ScaffoldMessenger), dùng sau khi pop.
  final BuildContext hostContext;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  late final TextEditingController _oldCtrl;
  late final TextEditingController _newCtrl;
  late final TextEditingController _confirmCtrl;
  bool _submitting = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _oldCtrl = TextEditingController();
    _newCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String hint) {
    final fieldRadius = BorderRadius.circular(12.r);
    final borderSide = BorderSide(
      color: context.palette.borderDefault.withValues(alpha: 0.65),
    );
    final focusedSide = BorderSide(color: context.palette.toolButton, width: 1.5);
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: context.palette.toolButton.withValues(alpha: 0.1),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      hintStyle: TextStyle(
        color: context.palette.secondaryText.withValues(alpha: 0.88),
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        height: 1.35,
      ),
      border: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: focusedSide,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(
          color: context.palette.borderDefault.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  static const TextStyle _inputStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0.2,
  );

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = (user?.email ?? '').trim();
    final oldPw = _oldCtrl.text.trim();
    final newPw = _newCtrl.text.trim();
    final confirmPw = _confirmCtrl.text.trim();

    if (email.isEmpty || user == null) {
      setState(() => _err = 'Không tìm thấy tài khoản đăng nhập.');
      return;
    }
    if (oldPw.isEmpty || newPw.isEmpty) {
      setState(() => _err = 'Vui lòng nhập đầy đủ thông tin.');
      return;
    }
    if (newPw.length < 6) {
      setState(() => _err = 'Mật khẩu mới cần ít nhất 6 ký tự.');
      return;
    }
    if (newPw != confirmPw) {
      setState(() => _err = 'Xác nhận mật khẩu mới không khớp.');
      return;
    }
    if (oldPw == newPw) {
      setState(() => _err = 'Mật khẩu mới phải khác mật khẩu cũ.');
      return;
    }

    setState(() {
      _submitting = true;
      _err = null;
    });

    var success = false;
    try {
      final cred = EmailAuthProvider.credential(email: email, password: oldPw);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPw);
      success = true;
      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.hostContext.mounted) {
        ScaffoldMessenger.of(widget.hostContext).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _err = 'Mật khẩu cũ không chính xác.';
        } else if (e.code == 'weak-password') {
          _err = 'Mật khẩu mới quá yếu.';
        } else {
          _err = 'Không thể đổi mật khẩu (${e.code}).';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _err = 'Không thể đổi mật khẩu. Vui lòng thử lại.');
    } finally {
      if (!success && mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputStyle = _inputStyle.copyWith(
      color: context.palette.primaryText,
      fontSize: 14.sp,
    );

    return AlertDialog(
      backgroundColor: context.palette.backgroundWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      titlePadding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 8.h),
      contentPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
      actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
      title: Text(
        'Đổi mật khẩu',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: context.palette.primaryText,
          letterSpacing: 0.2,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _oldCtrl,
                obscureText: true,
                enabled: !_submitting,
                cursorColor: context.palette.blueDarkText,
                style: inputStyle,
                decoration: _deco('Mật khẩu cũ'),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _newCtrl,
                obscureText: true,
                enabled: !_submitting,
                cursorColor: context.palette.blueDarkText,
                style: inputStyle,
                decoration: _deco('Mật khẩu mới'),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                enabled: !_submitting,
                cursorColor: context.palette.blueDarkText,
                style: inputStyle,
                decoration: _deco('Xác nhận mật khẩu mới'),
              ),
              if (_err != null) ...[
                SizedBox(height: 10.h),
                Text(
                  _err!,
                  style: TextStyle(
                    color: context.palette.errorText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: context.palette.secondaryText,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          child: const Text('Hủy'),
        ),
        SizedBox(width: 4.w),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: context.palette.darkBlueCard,
            foregroundColor: context.palette.whiteText,
            disabledBackgroundColor: context.palette.borderDefault.withValues(
              alpha: 0.5,
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            textStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
          ),
          child: _submitting
              ? SizedBox(
                  width: 18.w,
                  height: 18.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}
