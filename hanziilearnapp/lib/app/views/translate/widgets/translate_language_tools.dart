import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class TranslateLanguageTools extends StatelessWidget {
  const TranslateLanguageTools({
    super.key,
    required this.isVietnameseToChinese,
    required this.isListening,
    required this.onSwitchLanguage,
    required this.onToggleListening,
    required this.onPickImage,
    required this.onOpenHandwritingPad,
  });

  final bool isVietnameseToChinese;
  final bool isListening;
  final VoidCallback onSwitchLanguage;
  final VoidCallback onToggleListening;
  final VoidCallback onPickImage;
  final VoidCallback onOpenHandwritingPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault, width: 1.w),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLangChip(
                isVietnameseToChinese ? 'Việt' : 'Trung (Giản thể)',
              ),
              GestureDetector(
                onTap: onSwitchLanguage,
                child: Image.asset(
                  'assets/iconic/exchange_ic.png',
                  width: 22.w,
                  height: 22.h,
                ),
              ),
              _buildLangChip(
                isVietnameseToChinese ? 'Trung (Giản thể)' : 'Việt',
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolButton(
                iconPath: 'assets/iconic/microphone_ic.png',
                onTap: onToggleListening,
                isActive: isListening,
              ),
              GestureDetector(
                onTap: onPickImage,
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child: Image.asset(
                    'assets/iconic/camera_ic.png',
                    width: 30.w,
                    height: 30.h,
                  ),
                ),
              ),
              _toolButton(
                iconPath: 'assets/iconic/writing_ic.png',
                onTap: onOpenHandwritingPad,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String label) {
    return Container(
      width: 120.w,
      height: 30.h,
      decoration: BoxDecoration(
        color: AppColors.whiteCard,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _toolButton({
    required String iconPath,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blueDarkText : AppColors.toolButton,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(color: AppColors.backgroundWhite, width: 2.w),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.blueDarkText.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Image.asset(
          iconPath,
          width: 28.w,
          height: 28.h,
          color: AppColors.whiteText.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
