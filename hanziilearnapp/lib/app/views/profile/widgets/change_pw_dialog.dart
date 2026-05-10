import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

Future<void> showChangePwDlg(BuildContext context) async {
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool submitting = false;
  String? err;

  await showDialog<void>(
    context: context,
    builder: (dlgCtx) {
      return StatefulBuilder(
        builder: (context, setDlg) {
          InputDecoration deco(String hint) {
            return InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            );
          }

          Future<void> submit() async {
            final user = FirebaseAuth.instance.currentUser;
            final email = (user?.email ?? '').trim();
            final oldPw = oldCtrl.text.trim();
            final newPw = newCtrl.text.trim();
            final confirmPw = confirmCtrl.text.trim();

            if (email.isEmpty || user == null) {
              setDlg(() => err = 'Không tìm thấy tài khoản đăng nhập.');
              return;
            }
            if (oldPw.isEmpty || newPw.isEmpty) {
              setDlg(() => err = 'Vui lòng nhập đầy đủ thông tin.');
              return;
            }
            if (newPw.length < 6) {
              setDlg(() => err = 'Mật khẩu mới cần ít nhất 6 ký tự.');
              return;
            }
            if (newPw != confirmPw) {
              setDlg(() => err = 'Xác nhận mật khẩu mới không khớp.');
              return;
            }
            if (oldPw == newPw) {
              setDlg(() => err = 'Mật khẩu mới phải khác mật khẩu cũ.');
              return;
            }

            setDlg(() {
              submitting = true;
              err = null;
            });

            try {
              final cred = EmailAuthProvider.credential(email: email, password: oldPw);
              await user.reauthenticateWithCredential(cred);
              await user.updatePassword(newPw);
              if (!context.mounted) return;
              Navigator.pop(dlgCtx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công.')));
            } on FirebaseAuthException catch (e) {
              setDlg(() {
                if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                  err = 'Mật khẩu cũ không chính xác.';
                } else if (e.code == 'weak-password') {
                  err = 'Mật khẩu mới quá yếu.';
                } else {
                  err = 'Không thể đổi mật khẩu (${e.code}).';
                }
              });
            } catch (_) {
              setDlg(() => err = 'Không thể đổi mật khẩu. Vui lòng thử lại.');
            } finally {
              setDlg(() => submitting = false);
            }
          }

          return AlertDialog(
            title: const Text('Đổi mật khẩu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldCtrl,
                  obscureText: true,
                  enabled: !submitting,
                  decoration: deco('Mật khẩu cũ'),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  enabled: !submitting,
                  decoration: deco('Mật khẩu mới'),
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  enabled: !submitting,
                  decoration: deco('Xác nhận mật khẩu mới'),
                ),
                if (err != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    err!,
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
                onPressed: submitting ? null : () => Navigator.pop(dlgCtx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: submitting ? null : submit,
                child:
                    submitting
                        ? SizedBox(
                          width: 16.w,
                          height: 16.h,
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

  oldCtrl.dispose();
  newCtrl.dispose();
  confirmCtrl.dispose();
}
