import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, this.topSpacing = 20});

  final String title;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: topSpacing.h),
        Image.asset(
          'assets/logo/logo_login_signin.jpg',
          width: 260.w,
          height: 260.h,
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.blueDarkText,
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }
}
