import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/providers/auth_provider.dart';
import 'package:hanziilearnapp/app/routes/app_routes.dart';
import 'package:hanziilearnapp/app/views/authencation/login_view.dart';
import 'package:hanziilearnapp/app/views/authencation/signup/signup_form_section.dart';
import 'package:hanziilearnapp/app/views/authencation/signup/signup_validation.dart';
import 'package:provider/provider.dart';

class SigninView extends StatefulWidget {
  const SigninView({super.key});

  @override
  State<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends State<SigninView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isWaitingVerification = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
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
              SizedBox(height: 16.h),
              Image.asset(
                'assets/logo/logo_login_signin.jpg',
                width: 260.w,
                height: 260.h,
              ),
              Text(
                'ĐĂNG KÝ',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blueDarkText,
                ),
              ),
              SizedBox(height: 10.h),
              SignupFormSection(
                formKey: _formKey,
                emailController: _emailController,
                nameController: _nameController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                obscurePassword: _obscurePassword,
                obscureConfirmPassword: _obscureConfirmPassword,
                isLoading: isLoading,
                onTogglePassword: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onToggleConfirmPassword: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                onRegisterPressed: _onRegisterPressed,
                onGoToLogin: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                  );
                },
                validateEmail: validateSignupEmail,
                validateUsername: validateSignupUsername,
                validatePassword: validateSignupPassword,
                validateConfirmPassword: (value) =>
                    validateSignupConfirmPassword(
                      value: value,
                      originalPassword: _passwordController.text,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRegisterPressed() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.startRegisterWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        usernameVie: _nameController.text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi email xác thực. Bạn có 2 phút để xác thực email.',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          backgroundColor: AppColors.cardItem,
        ),
      );
      await _waitForEmailVerificationOrTimeout();
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mapRegisterError(error),
            style: TextStyle(color: AppColors.errorText),
          ),
          backgroundColor: AppColors.backgroundLight,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể đăng ký tài khoản.',
            style: TextStyle(color: AppColors.blueDarkText),
          ),
          backgroundColor: AppColors.backgroundLight,
        ),
      );
    }
  }

  Future<void> _waitForEmailVerificationOrTimeout() async {
    if (!mounted) {
      return;
    }

    const timeoutSeconds = 120;
    var remainingSeconds = timeoutSeconds;
    _isWaitingVerification = true;
    final authProvider = context.read<AuthProvider>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> runTimer() async {
              while (_isWaitingVerification && remainingSeconds > 0) {
                await Future<void>.delayed(const Duration(seconds: 1));
                if (!_isWaitingVerification ||
                    !mounted ||
                    !dialogContext.mounted) {
                  return;
                }

                final verified = await authProvider
                    .checkAndFinalizeEmailVerification();
                if (!mounted || !dialogContext.mounted) {
                  return;
                }

                if (verified) {
                  _isWaitingVerification = false;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đăng ký thành công!',
                        style: TextStyle(color: AppColors.greenText),
                      ),
                      backgroundColor: AppColors.backgroundLight,
                    ),
                  );
                  Navigator.pushNamedAndRemoveUntil(
                    this.context,
                    AppRoutes.main,
                    (route) => false,
                  );
                  return;
                }

                remainingSeconds--;
                setDialogState(() {});
              }

              if (!_isWaitingVerification ||
                  !mounted ||
                  !dialogContext.mounted) {
                return;
              }

              _isWaitingVerification = false;
              await authProvider.cancelPendingRegistration();
              if (!mounted || !dialogContext.mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Quá 2 phút chưa xác thực. Đăng ký đã bị hủy, vui lòng đăng ký lại.',
                    style: TextStyle(color: AppColors.errorText),
                  ),
                  backgroundColor: AppColors.backgroundLight,
                ),
              );
              Navigator.pushAndRemoveUntil(
                this.context,
                MaterialPageRoute(builder: (_) => const SigninView()),
                (route) => false,
              );
            }

            if (remainingSeconds == timeoutSeconds) {
              runTimer();
            }

            final mm = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
            final ss = (remainingSeconds % 60).toString().padLeft(2, '0');

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
                      color: AppColors.blueDarkText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    _isWaitingVerification = false;
                    await authProvider.cancelPendingRegistration();
                    if (!mounted || !dialogContext.mounted) {
                      return;
                    }
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Đăng ký đã bị hủy.')),
                    );
                  },
                  child: const Text('Hủy đăng ký'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
