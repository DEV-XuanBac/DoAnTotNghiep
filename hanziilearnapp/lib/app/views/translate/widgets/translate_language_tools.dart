import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';

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
        color: context.palette.lightCardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.palette.borderDefault, width: 1.w),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _buildLangChip(
                  context,
                  isVietnameseToChinese ? 'Việt' : 'Trung (GT)',
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: GestureDetector(
                  onTap: onSwitchLanguage,
                  child: Image.asset(
                    'assets/iconic/exchange_ic.png',
                    width: 22.w,
                    height: 22.h,
                  ),
                ),
              ),
              Flexible(
                child: _buildLangChip(
                  context,
                  isVietnameseToChinese ? 'Trung (GT)' : 'Việt',
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _toolButton(
                context,
                iconPath: 'assets/iconic/microphone_ic.png',
                onTap: onToggleListening,
                isActive: isListening,
              ),
              GestureDetector(
                onTap: onPickImage,
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: context.palette.backgroundWhite,
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
                context,
                iconPath: 'assets/iconic/writing_ic.png',
                onTap: onOpenHandwritingPad,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(BuildContext context, String label) {
    return Align(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: Container(
          height: 34.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: context.palette.whiteCard,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: context.palette.borderEnable,
              width: 0.8.w,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.palette.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolButton(
    BuildContext context, {
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
          color: isActive
              ? context.palette.blueDarkText
              : context.palette.toolButton,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(
            color: context.palette.backgroundWhite,
            width: 2.w,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: context.palette.blueDarkText.withValues(alpha: 0.25),
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
          color: context.palette.whiteText.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
