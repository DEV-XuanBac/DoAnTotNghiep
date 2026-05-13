import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/router/app_router.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/providers/auth_provider.dart';
import 'package:hanziilearnapp/app/views/authencation/controllers/signup_controller.dart';
import 'package:hanziilearnapp/app/views/authencation/signup/signup_form_section.dart';
import 'package:hanziilearnapp/app/views/authencation/signup/signup_validation.dart';
import 'package:hanziilearnapp/app/views/authencation/widgets/auth_header.dart';
import 'package:provider/provider.dart';

class SigninView extends StatefulWidget {
  const SigninView({super.key});

  @override
  State<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends State<SigninView> {
  final SignupController _ctl = SignupController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.registering;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const AuthHeader(title: 'ĐĂNG KÝ', topSpacing: 16),
              ListenableBuilder(
                listenable: _ctl,
                builder: (context, _) {
                  return SignupFormSection(
                    formK: _ctl.formK,
                    emailCtrl: _ctl.emailCtrl,
                    nameCtrl: _ctl.nameCtrl,
                    passCtrl: _ctl.passCtrl,
                    confirmPassCtrl: _ctl.confirmPassCtrl,
                    hidePw: _ctl.hidePw,
                    hideConfirmPw: _ctl.hideConfirmPw,
                    loading: isLoading,
                    onTogglePw: _ctl.togglePw,
                    onToggleConfirmPw: _ctl.toggleConfirmPw,
                    onRegister: _onRegisterPressed,
                    onGoLogin: () => AppRouter.pushLogin(context),
                    validateMail: validateSignupEmail,
                    validateName: validateSignupUsername,
                    validatePass: validateSignupPassword,
                    validateConfirmPass: _ctl.validateConfirmPassword,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRegisterPressed() async {
    FocusScope.of(context).unfocus();
    final authPrv = context.read<AuthProvider>();
    final errMsg = await _ctl.register(authPrv);
    if (!mounted) return;
    if (errMsg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi email xác thực. Bạn có 2 phút để xác thực email.',
            style: TextStyle(
              color: context.palette.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          backgroundColor: context.palette.cardItem,
        ),
      );
      await _waitForEmailVerificationOrTimeout();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errMsg,
          style: TextStyle(color: context.palette.errorText),
        ),
        backgroundColor: context.palette.backgroundLight,
      ),
    );
  }

  Future<void> _waitForEmailVerificationOrTimeout() async {
    const timeoutSeconds = 120;
    final authPrv = context.read<AuthProvider>();
    _ctl.beginWait(timeoutSeconds);
    var dialogDismissed = false;

    unawaited(
      showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ListenableBuilder(
          listenable: _ctl,
          builder: (context, _) {
            final mm = (_ctl.remainSecs ~/ 60)
                .toString()
                .padLeft(2, '0');
            final ss = (_ctl.remainSecs % 60)
                .toString()
                .padLeft(2, '0');
            return AlertDialog(
              title: const Text('Chờ xác thực email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vui lòng vào email và bấm vào link xác thực để hoàn tất đăng ký.',
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Thời gian còn lại: $mm:$ss',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.palette.blueDarkText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _ctl.cancelWait(authPrv);
                    if (!mounted || !dialogContext.mounted) return;
                    dialogDismissed = true;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Hủy đăng ký'),
                ),
              ],
            );
          },
        );
      },
    ));

    final outcome = await _ctl.waitVerify(authPrv);
    if (!mounted) return;
    if (!dialogDismissed) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    switch (outcome) {
      case SignupVerificationOutcome.verified:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đăng ký thành công!',
              style: TextStyle(color: context.palette.greenText),
            ),
            backgroundColor: context.palette.backgroundLight,
          ),
        );
        unawaited(AppRouter.goToMainTab(context));
        break;
      case SignupVerificationOutcome.timeout:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quá 2 phút chưa xác thực. Đăng ký đã bị hủy, vui lòng đăng ký lại.',
              style: TextStyle(color: context.palette.errorText),
            ),
            backgroundColor: context.palette.backgroundLight,
          ),
        );
        break;
      case SignupVerificationOutcome.cancelled:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đăng ký đã bị hủy.')));
        break;
    }
  }
}
