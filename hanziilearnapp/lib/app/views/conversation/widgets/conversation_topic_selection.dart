import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/core/constants/conversation_constants.dart';
import 'package:hanziilearnapp/app/datasource/network_services/conversation_ai_service.dart';
import 'package:hanziilearnapp/app/models/conversation_model.dart';

class ConversationTopicSelection extends StatelessWidget {
  const ConversationTopicSelection({
    super.key,
    required this.hsk,
    required this.err,
    required this.onHsk,
    required this.onTopic,
  });

  final int hsk;
  final String? err;
  final ValueChanged<int> onHsk;
  final ValueChanged<ConversationTopic> onTopic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ConversationConstants.topicTitle,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            ConversationConstants.topicSubtitle,
            style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
          ),
          SizedBox(height: 12.h),
          _HskRow(hsk: hsk, onHsk: onHsk),
          SizedBox(height: 14.h),
          if (err != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.errorText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                err!,
                style: TextStyle(color: AppColors.errorText, fontSize: 13.sp),
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 1.5,
              ),
              itemCount: ConversationAiService.availableTopics.length,
              itemBuilder: (_, i) {
                final t = ConversationAiService.availableTopics[i];
                return _TopicTile(t: t, onTap: () => onTopic(t));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HskRow extends StatelessWidget {
  const _HskRow({required this.hsk, required this.onHsk});

  final int hsk;
  final ValueChanged<int> onHsk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.borderDefault.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            ConversationConstants.lvlLabel,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(6, (i) {
                  final n = i + 1;
                  final on = n == hsk;
                  return Padding(
                    padding: EdgeInsets.only(right: 6.w),
                    child: GestureDetector(
                      onTap: () => onHsk(n),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: on
                              ? AppColors.darkBlueCard
                              : AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: on
                                ? AppColors.darkBlueCard
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Text(
                          'HSK$n',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: on
                                ? AppColors.whiteText
                                : AppColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.t, required this.onTap});

  final ConversationTopic t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.darkBlueCard.withValues(alpha: 0.85),
              AppColors.darkGreenCard.withValues(alpha: 0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBlueCard.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(t.icon, style: TextStyle(fontSize: 30.sp)),
            SizedBox(height: 6.h),
            Text(
              t.nameCn,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteText,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              t.nameVi,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.whiteText.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
