import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class ProfileNameRow extends StatelessWidget {
  const ProfileNameRow({
    super.key,
    required this.label,
    required this.hint,
    required this.ctrl,
    required this.node,
    required this.saving,
    required this.changed,
    required this.canEdit,
    required this.textColor,
    required this.borderColor,
    required this.onChanged,
    required this.onSubmit,
    required this.onSaveTap,
  });

  final String label;
  final String hint;
  final TextEditingController ctrl;
  final FocusNode node;
  final bool saving;
  final bool changed;
  final bool canEdit;
  final Color textColor;
  final Color borderColor;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: TextField(
            controller: ctrl,
            focusNode: node,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            readOnly: !canEdit,
            onChanged: onChanged,
            onSubmitted: onSubmit,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        if (saving)
          SizedBox(
            width: 20.w,
            height: 20.h,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        else if (changed)
          IconButton(
            tooltip: 'Xác nhận $label',
            onPressed: canEdit ? onSaveTap : null,
            icon: Icon(Icons.check_circle_rounded, size: 22.sp, color: AppColors.greenText),
          )
        else
          SizedBox(width: 40.w),
      ],
    );
  }
}
