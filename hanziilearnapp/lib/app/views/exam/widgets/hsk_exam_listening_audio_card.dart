import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';

class HskExamListeningAudioCard extends StatelessWidget {
  const HskExamListeningAudioCard({
    super.key,
    required this.audioAssetPath,
    required this.isAudioPlaying,
    required this.audioDuration,
    required this.audioPosition,
    required this.onToggleAudio,
    required this.formatDuration,
  });

  final String? audioAssetPath;
  final bool isAudioPlaying;
  final Duration audioDuration;
  final Duration audioPosition;
  final ValueChanged<String> onToggleAudio;
  final String Function(Duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    final maxMs = audioDuration.inMilliseconds > 0
        ? audioDuration.inMilliseconds.toDouble()
        : 1.0;
    final valueMs = audioPosition.inMilliseconds
        .clamp(0, maxMs.toInt())
        .toDouble();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.palette.lightCardBackground,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: context.palette.borderDefault.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listening (câu 1-20): nghe file audio để làm bài',
            style: TextStyle(
              color: context.palette.primaryText,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          if (audioAssetPath == null) ...[
            Text(
              'Phần nghe này chưa được cập nhật file audio.',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.palette.secondaryText,
              ),
            ),
          ] else ...[
            Row(
              children: [
                IconButton(
                  onPressed: () => onToggleAudio(audioAssetPath!),
                  icon: Icon(
                    isAudioPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: context.palette.bottomButton,
                    size: 30.sp,
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    minHeight: 4.h,
                    borderRadius: BorderRadius.circular(99.r),
                    value: maxMs <= 1 ? 0 : (valueMs / maxMs).clamp(0.0, 1.0),
                  ),
                ),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${formatDuration(audioPosition)} / ${formatDuration(audioDuration)}',
              style: TextStyle(
                fontSize: 11.sp,
                color: context.palette.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
