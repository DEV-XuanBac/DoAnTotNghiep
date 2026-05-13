import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';

class HomeSearchCard extends StatelessWidget {
  const HomeSearchCard({
    super.key,
    required this.textCtrl,
    required this.isViMode,
    required this.listening,
    required this.handwritingBusy,
    required this.onSearch,
    required this.onToggleMic,
    required this.onHandwriting,
    required this.onToggleMode,
  });

  final TextEditingController textCtrl;
  final bool isViMode;
  final bool listening;
  final bool handwritingBusy;
  final VoidCallback onSearch;
  final VoidCallback onToggleMic;
  final VoidCallback onHandwriting;
  final ValueChanged<bool> onToggleMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.palette.lightCardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.palette.borderDefault.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onSearch,
                icon: Icon(
                  Icons.search,
                  color: context.palette.secondaryText,
                  size: 30.w,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: textCtrl,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: isViMode
                        ? 'Nhập tiếng Việt'
                        : 'Nhập tiếng Hán',
                    hintStyle: TextStyle(
                      color: context.palette.secondaryText.withValues(
                        alpha: 0.8,
                      ),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: context.palette.primaryText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: context.palette.toggleBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToggleChip(
                      label: 'CN',
                      isSelected: !isViMode,
                      onTap: () => onToggleMode(false),
                    ),
                    _ToggleChip(
                      label: 'VI',
                      isSelected: isViMode,
                      onTap: () => onToggleMode(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                img: 'assets/iconic/microphone_ic.png',
                onTap: onToggleMic,
                isActive: listening,
              ),
              _ActionButton(
                img: 'assets/iconic/pen_ic.png',
                onTap: onHandwriting,
                isActive: handwritingBusy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? context.palette.toggleSelected
              : context.palette.toggleBg,
          borderRadius: BorderRadius.circular(14.w),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.img,
    required this.onTap,
    required this.isActive,
  });

  final String img;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive
              ? context.palette.blueDarkText.withValues(alpha: 0.85)
              : context.palette.cardItem.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14.w),
        ),
        child: Image.asset(
          img,
          width: 20.w,
          height: 20.h,
          color: isActive
              ? context.palette.whiteText
              : context.palette.lightBlackText.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
