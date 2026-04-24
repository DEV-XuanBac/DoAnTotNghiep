import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/views/community/community_tab_type.dart';

class CommunityTabSelector extends StatelessWidget {
  const CommunityTabSelector({
    super.key,
    required this.currentTab,
    required this.onChanged,
  });

  final CommunityTabType currentTab;
  final ValueChanged<CommunityTabType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          _buildTabButton(CommunityTabType.all),
          SizedBox(width: 4.w),
          _buildTabButton(CommunityTabType.interacted),
          SizedBox(width: 4.w),
          _buildTabButton(CommunityTabType.manage),
        ],
      ),
    );
  }

  Widget _buildTabButton(CommunityTabType tab) {
    final isSelected = currentTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(tab),
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.blueDarkText : Colors.transparent,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Text(
            tab.label,
            style: TextStyle(
              color: isSelected ? AppColors.whiteText : AppColors.primaryText,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }
}
