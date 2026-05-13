import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';

class CameraCaptureControls extends StatelessWidget {
  const CameraCaptureControls({
    super.key,
    required this.isCapturing,
    required this.onSwitchCamera,
    required this.onCapture,
    required this.onClose,
  });

  final bool isCapturing;
  final VoidCallback onSwitchCamera;
  final VoidCallback onCapture;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onSwitchCamera,
              icon: Icon(
                Icons.flip_camera_ios_rounded,
                size: 28.sp,
                color: context.palette.whiteText,
              ),
            ),
            GestureDetector(
              onTap: onCapture,
              child: Container(
                width: 68.w,
                height: 68.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.palette.whiteText, width: 3.w),
                ),
                child: Center(
                  child: Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCapturing ? Colors.grey : context.palette.whiteText,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close_rounded,
                size: 28.sp,
                color: context.palette.whiteText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
