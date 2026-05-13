import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hanziilearnapp/app/core/router/app_router.dart';
import 'package:hanziilearnapp/app/providers/auth_provider.dart';
import 'package:hanziilearnapp/app/views/authencation/controllers/login_controller.dart';
import 'package:hanziilearnapp/app/views/authencation/login/login_form_section.dart';
import 'package:hanziilearnapp/app/views/authencation/widgets/auth_header.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _ctl = LoginController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.signingIn;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const AuthHeader(title: 'ĐĂNG NHẬP'),
              ListenableBuilder(
                listenable: _ctl,
                builder: (context, _) {
                  return LoginFormSection(
                    formK: _ctl.formK,
                    emailCtrl: _ctl.emailCtrl,
                    passCtrl: _ctl.passCtrl,
                    hidePw: _ctl.hidePw,
                    loading: isLoading,
                    onTogglePw: _ctl.togglePw,
                    onLogin: _onLoginPressed,
                    onGoSignup: () => AppRouter.pushSignup(context),
                    validateMail: _ctl.validateEmail,
                    validatePass: _ctl.validatePassword,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    final authPrv = context.read<AuthProvider>();
    final errMsg = await _ctl.submit(authPrv);
    if (!mounted) {
      return;
    }
    if (errMsg == null) {
      unawaited(AppRouter.goToMainTab(context));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errMsg)));
  }
}
