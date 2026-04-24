import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class LoginFormSection extends StatelessWidget {
  const LoginFormSection({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLoginPressed,
    required this.onGoToSignup,
    required this.validateEmail,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLoginPressed;
  final VoidCallback onGoToSignup;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Email:'),
            SizedBox(height: 5.h),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              decoration: _inputDecoration(
                hint: 'Nhập email của bạn',
                icon: Icons.email_outlined,
              ),
            ),
            SizedBox(height: 14.h),
            _buildLabel('Mật khẩu:'),
            SizedBox(height: 5.h),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              validator: validatePassword,
              decoration: _inputDecoration(
                hint: 'Nhập mật khẩu của bạn',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLoginPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueDarkText.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  elevation: 2,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.whiteText,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Bạn chưa có tài khoản? ",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
                GestureDetector(
                  onTap: onGoToSignup,
                  child: Text(
                    "Đăng ký",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.blueDarkText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 14.sp, color: AppColors.primaryText),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      prefixIcon: Icon(
        icon,
        color: AppColors.secondaryText.withValues(alpha: 0.8),
      ),
      suffixIcon: suffix,
      hintStyle: TextStyle(
        fontSize: 14.sp,
        color: AppColors.secondaryText.withValues(alpha: 0.8),
      ),
    );
  }
}
