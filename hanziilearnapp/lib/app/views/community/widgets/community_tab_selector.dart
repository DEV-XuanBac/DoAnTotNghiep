import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
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
        color: context.palette.backgroundWhite,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        children: [
          _buildTabButton(context, CommunityTabType.all),
          SizedBox(width: 4.w),
          _buildTabButton(context, CommunityTabType.interacted),
          SizedBox(width: 4.w),
          _buildTabButton(context, CommunityTabType.manage),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, CommunityTabType tab) {
    final isSelected = currentTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(tab),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? context.palette.blueDarkText : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            tab.label,
            style: TextStyle(
              color: isSelected ? context.palette.whiteText : context.palette.primaryText,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ),
      ),
    );
  }
}
