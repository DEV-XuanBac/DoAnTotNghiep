import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/core/constants/conversation_constants.dart';
import 'package:hanziilearnapp/app/models/conversation_model.dart';
import 'package:hanziilearnapp/app/models/pronunciation_result.dart';
import 'package:hanziilearnapp/app/views/community/widgets/community_avatar.dart';

class ConversationMessageBubble extends StatelessWidget {
  const ConversationMessageBubble({
    super.key,
    required this.msg,
    required this.active,
    required this.pron,
    required this.avatar,
    required this.onPlay,
  });

  final ConversationMessage msg;
  final bool active;
  final PronunciationResult? pron;
  final String avatar;
  final ValueChanged<String> onPlay;

  @override
  Widget build(BuildContext context) {
    final me = msg.isUserTurn;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!me) _avatarChip('AI', AppColors.darkBlueCard),
          if (!me) SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: me
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    me
                        ? ConversationConstants.speakerYou
                        : ConversationConstants.speakerBot,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: me
                        ? AppColors.darkBlueCard.withValues(alpha: 0.1)
                        : AppColors.backgroundWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(me ? 16.r : 4.r),
                      topRight: Radius.circular(me ? 4.r : 16.r),
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: Radius.circular(16.r),
                    ),
                    border: active
                        ? Border.all(
                            color: AppColors.darkBlueCard.withValues(
                              alpha: 0.5,
                            ),
                            width: 1.5,
                          )
                        : Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: me
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.chinese,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        msg.pinyin,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.blueDarkText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        msg.vietnamese,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.secondaryText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      GestureDetector(
                        onTap: () => onPlay(msg.chinese),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              size: 18.sp,
                              color: AppColors.toolButton,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              ConversationConstants.listen,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.toolButton,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (me && pron != null) _PronRow(pron: pron!),
              ],
            ),
          ),
          if (me) SizedBox(width: 8.w),
          if (me) CommunityAvatar(avatar: avatar, size: 36),
        ],
      ),
    );
  }

  Widget _avatarChip(String label, Color bg) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.whiteText,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PronRow extends StatelessWidget {
  const _PronRow({required this.pron});

  final PronunciationResult pron;

  @override
  Widget build(BuildContext context) {
    if (pron.errorMessage != null) {
      return Padding(
        padding: EdgeInsets.only(top: 6.h),
        child: Text(
          '${ConversationConstants.scoreErrPrefix} ${pron.errorMessage}',
          style: TextStyle(color: AppColors.errorText, fontSize: 12.sp),
        ),
      );
    }

    final pts = pron.overallScore.round();
    final color = pts >= 80
        ? AppColors.greenText
        : pts >= 60
        ? AppColors.blueDarkText
        : AppColors.errorText;

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pts >= 80
                ? Icons.emoji_events_rounded
                : pts >= 60
                ? Icons.thumb_up_alt_rounded
                : Icons.refresh_rounded,
            color: color,
            size: 18.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            '${ConversationConstants.scorePrefix} $pts/100',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '${ConversationConstants.scoreCxPrefix}'
            '${pron.accuracyScore.round()} TC:${pron.fluencyScore.round()} '
            'HT:${pron.completenessScore.round()}',
            style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
