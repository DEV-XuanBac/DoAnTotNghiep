import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class LoginFormSection extends StatelessWidget {
  const LoginFormSection({
    super.key,
    required this.formK,
    required this.emailCtrl,
    required this.passCtrl,
    required this.hidePw,
    required this.loading,
    required this.onTogglePw,
    required this.onLogin,
    required this.onGoSignup,
    required this.validateMail,
    required this.validatePass,
  });

  final GlobalKey<FormState> formK;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool hidePw;
  final bool loading;
  final VoidCallback onTogglePw;
  final VoidCallback onLogin;
  final VoidCallback onGoSignup;
  final String? Function(String?) validateMail;
  final String? Function(String?) validatePass;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formK,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Email:'),
            SizedBox(height: 5.h),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: validateMail,
              decoration: _inputDecoration(
                hint: 'Nhập email của bạn',
                icon: Icons.email_outlined,
              ),
            ),
            SizedBox(height: 14.h),
            _buildLabel('Mật khẩu:'),
            SizedBox(height: 5.h),
            TextFormField(
              controller: passCtrl,
              obscureText: hidePw,
              validator: validatePass,
              decoration: _inputDecoration(
                hint: 'Nhập mật khẩu của bạn',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    hidePw
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.secondaryText,
                  ),
                  onPressed: onTogglePw,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: loading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueDarkText.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  elevation: 2,
                ),
                child: loading
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
                  onTap: onGoSignup,
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
