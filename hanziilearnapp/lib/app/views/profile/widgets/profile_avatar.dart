import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.url,
    required this.uploading,
  });

  final String url;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    const fallback = 'assets/logo/friend_logo.png';
    Widget img;
    if (url.isEmpty) {
      img = Image.asset(fallback, width: 80.w, height: 80.h, fit: BoxFit.cover);
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      img = Image.network(
        url,
        width: 80.w,
        height: 80.h,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                Image.asset(fallback, width: 80.w, height: 80.h, fit: BoxFit.cover),
      );
    } else {
      img = Image.asset(
        url,
        width: 80.w,
        height: 80.h,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                Image.asset(fallback, width: 80.w, height: 80.h, fit: BoxFit.cover),
      );
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderDefault, width: 1.w),
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(50.r), child: img),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: AppColors.blueDarkText,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.whiteText, width: 1.w),
            ),
            child:
                uploading
                    ? Padding(
                      padding: EdgeInsets.all(5.w),
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: AppColors.whiteText,
                      ),
                    )
                    : Icon(Icons.camera_alt_rounded, size: 14.sp, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
