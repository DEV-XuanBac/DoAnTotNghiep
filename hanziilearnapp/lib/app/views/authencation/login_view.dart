import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/providers/auth_provider.dart';
import 'package:hanziilearnapp/app/routes/app_routes.dart';
import 'package:hanziilearnapp/app/views/authencation/login/login_form_section.dart';
import 'package:hanziilearnapp/app/views/authencation/login/login_validation.dart';
import 'package:hanziilearnapp/app/views/authencation/signup_view.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              SizedBox(height: 20.h),
              Image.asset(
                'assets/logo/logo_login_signin.jpg',
                width: 260.w,
                height: 260.h,
              ),
              Text(
                'ĐĂNG NHẬP',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blueDarkText,
                ),
              ),
              SizedBox(height: 10.h),
              LoginFormSection(
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                isLoading: isLoading,
                onTogglePassword: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onLoginPressed: _onLoginPressed,
                onGoToSignup: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SigninView()),
                  );
                },
                validateEmail: validateLoginEmail,
                validatePassword: validateLoginPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mapLoginError(error))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đăng nhập, vui lòng thử lại.')),
      );
    }
  }
}
