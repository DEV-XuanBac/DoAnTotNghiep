import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/widgets/app_network_image.dart';

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
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.palette.borderDefault, width: 1.w),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50.r),
            child: AppNetworkImage(source: url, width: 80.w, height: 80.h),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: context.palette.blueDarkText,
              shape: BoxShape.circle,
              border: Border.all(color: context.palette.whiteText, width: 1.w),
            ),
            child: uploading
                ? Padding(
                    padding: EdgeInsets.all(5.w),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: context.palette.whiteText,
                    ),
                  )
                : Icon(
                    Icons.camera_alt_rounded,
                    size: 14.sp,
                    color: Colors.white,
                  ),
          ),
        ),
      ],
    );
  }
}
