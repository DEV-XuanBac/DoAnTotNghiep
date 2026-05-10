import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/core/constants/conversation_constants.dart';

class ConversationBottomBar extends StatelessWidget {
  const ConversationBottomBar({
    super.key,
    required this.step,
    required this.stepMax,
    required this.scoring,
    required this.done,
    required this.myTurn,
    required this.hasPron,
    required this.micOn,
    required this.live,
    required this.avg10,
    required this.tapMic,
    required this.onNext,
    required this.newTopic,
    required this.replay,
  });

  final int step;
  final int stepMax;
  final bool scoring;
  final bool done;
  final bool myTurn;
  final bool hasPron;
  final bool micOn;
  final String live;
  final double? avg10;
  final VoidCallback tapMic;
  final VoidCallback onNext;
  final VoidCallback newTopic;
  final VoidCallback replay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${ConversationConstants.stepPrefix} ${step + 1}/$stepMax',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: (step + 1) / stepMax,
                    backgroundColor: AppColors.borderDefault.withValues(
                      alpha: 0.45,
                    ),
                    valueColor: AlwaysStoppedAnimation(AppColors.darkBlueCard),
                    minHeight: 6.h,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (scoring)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8.w),
                Text(
                  ConversationConstants.assessing,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            )
          else if (done)
            _DoneBar(avg10: avg10, newTopic: newTopic, replay: replay)
          else if (myTurn && !hasPron)
            _MicBar(micOn: micOn, live: live, tapMic: tapMic)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(ConversationConstants.next),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlueCard,
                  foregroundColor: AppColors.whiteText,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MicBar extends StatelessWidget {
  const _MicBar({
    required this.micOn,
    required this.live,
    required this.tapMic,
  });

  final bool micOn;
  final String live;
  final VoidCallback tapMic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                micOn
                    ? ConversationConstants.recHint
                    : ConversationConstants.startRecHint,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: micOn
                      ? AppColors.errorText
                      : AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (micOn && live.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    live,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.blueDarkText,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: tapMic,
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: micOn ? AppColors.errorText : AppColors.darkBlueCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (micOn ? AppColors.errorText : AppColors.darkBlueCard)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              micOn ? Icons.stop_rounded : Icons.mic_rounded,
              color: AppColors.whiteText,
              size: 28.sp,
            ),
          ),
        ),
      ],
    );
  }
}

class _DoneBar extends StatelessWidget {
  const _DoneBar({
    required this.avg10,
    required this.newTopic,
    required this.replay,
  });

  final double? avg10;
  final VoidCallback newTopic;
  final VoidCallback replay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.greenCard.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.greenCard,
                size: 28.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ConversationConstants.doneTitle,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    if (avg10 != null)
                      Text(
                        '${ConversationConstants.totalPrefix} '
                        '${avg10!.toStringAsFixed(1)}/10',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: newTopic,
                icon: const Icon(Icons.topic_rounded),
                label: const Text(ConversationConstants.topicOther),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkBlueCard,
                  side: BorderSide(color: AppColors.darkBlueCard),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: replay,
                icon: const Icon(Icons.replay_rounded),
                label: const Text(ConversationConstants.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlueCard,
                  foregroundColor: AppColors.whiteText,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
