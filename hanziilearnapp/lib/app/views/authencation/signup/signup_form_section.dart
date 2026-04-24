import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class SignupFormSection extends StatelessWidget {
  const SignupFormSection({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.nameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onRegisterPressed,
    required this.onGoToLogin,
    required this.validateEmail,
    required this.validateUsername,
    required this.validatePassword,
    required this.validateConfirmPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onRegisterPressed;
  final VoidCallback onGoToLogin;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validateUsername;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirmPassword;

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
            SizedBox(height: 12.h),
            _buildLabel('Tên người dùng:'),
            SizedBox(height: 5.h),
            TextFormField(
              controller: nameController,
              validator: validateUsername,
              decoration: _inputDecoration(
                hint: 'Nhập tên người dùng tiếng Việt',
                icon: Icons.person_outline,
              ),
            ),
            SizedBox(height: 12.h),
            _buildLabel('Mật khẩu:'),
            SizedBox(height: 5.h),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              validator: validatePassword,
              decoration: _inputDecoration(
                hint: 'Mật khẩu tối thiểu 8 ký tự',
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
            SizedBox(height: 12.h),
            _buildLabel('Nhập lại mật khẩu:'),
            SizedBox(height: 5.h),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: obscureConfirmPassword,
              validator: validateConfirmPassword,
              decoration: _inputDecoration(
                hint: 'Nhập lại mật khẩu',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: onToggleConfirmPassword,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: isLoading ? null : onRegisterPressed,
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
                        'Đăng ký',
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
                  "Bạn đã có tài khoản? ",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
                GestureDetector(
                  onTap: onGoToLogin,
                  child: Text(
                    "Đăng nhập",
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
