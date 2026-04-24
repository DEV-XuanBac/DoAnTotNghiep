import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:provider/provider.dart';

class TopicSelectionTab extends StatelessWidget {
  const TopicSelectionTab({
    super.key,
    required this.hskLevel,
    required this.onTapTopic,
  });

  final String hskLevel;
  final Future<void> Function(String topic) onTapTopic;

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonProvider>(
      builder: (context, provider, _) {
        if (provider.loading && provider.topics.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.topics.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.errorMessage!, textAlign: TextAlign.center),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: () => provider.loadTopicsByHskLevel(hskLevel),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.topics.isEmpty) {
          return Center(child: Text('Chưa có dữ liệu chủ đề cho $hskLevel'));
        }

        return Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn chủ đề',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Chọn 1 đề tài để học từ vựng theo đúng ngữ cảnh.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13.sp),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  itemCount: provider.topics.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, index) {
                    final topic = provider.topics[index];
                    final completed = provider.isTopicCompleted(topic);
                    final percent = provider.getTopicCompletionPercent(topic);
                    return InkWell(
                      borderRadius: BorderRadius.circular(14.r),
                      onTap: () => onTapTopic(topic),
                      child: Ink(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: completed
                                ? AppColors.greenText
                                : AppColors.borderDefault.withValues(alpha: 0.6),
                            width: completed ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                topic,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (completed)
                              Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: Text(
                                  '${percent.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: AppColors.greenText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16.sp,
                              color: AppColors.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
