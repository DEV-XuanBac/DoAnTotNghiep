import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_listening_audio_card.dart';
import 'package:hanziilearnapp/app/views/exam/widgets/hsk_exam_question_image.dart';

/// Phần thân màn hình làm bài: header phần + danh sách câu hỏi (tách khỏi HskExamTakeView).
class HskExamSectionContent extends StatelessWidget {
  const HskExamSectionContent({
    super.key,
    required this.exam,
    required this.currentSectionIndex,
    required this.progressText,
    required this.questionImagePath,
    required this.imageHeight,
    required this.onTapQuestionImage,
    required this.questionScrollController,
    required this.showListeningCard,
    required this.listeningAudioPath,
    required this.isAudioPlaying,
    required this.audioDuration,
    required this.audioPosition,
    required this.onToggleAudio,
    required this.formatDuration,
    required this.questionWidgets,
  });

  final HskExamDetail exam;
  final int currentSectionIndex;
  final String progressText;
  final String? questionImagePath;
  final double imageHeight;
  final VoidCallback onTapQuestionImage;
  final ScrollController questionScrollController;
  final bool showListeningCard;
  final String? listeningAudioPath;
  final bool isAudioPlaying;
  final Duration audioDuration;
  final Duration audioPosition;
  final ValueChanged<String> onToggleAudio;
  final String Function(Duration duration) formatDuration;
  final List<Widget> questionWidgets;

  @override
  Widget build(BuildContext context) {
    final sections = exam.sections;
    final currentSection = sections[currentSectionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          color: context.palette.backgroundWhite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam.title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.palette.primaryText,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                progressText,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.palette.secondaryText,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                currentSection.sectionTitle,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: context.palette.primaryText,
                ),
              ),
              SizedBox(height: 10.h),
              if (questionImagePath != null &&
                  questionImagePath!.trim().isNotEmpty) ...[
                HskExamQuestionImageTile(
                  imagePath: questionImagePath!.trim(),
                  imageHeight: imageHeight,
                  onTap: onTapQuestionImage,
                ),
                SizedBox(height: 10.h),
              ],
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: context.palette.backgroundWhite,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.palette.borderDefault.withValues(alpha: 0.7),
              ),
            ),
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (notification) {
                notification.disallowIndicator();
                return true;
              },
              child: ListView(
                controller: questionScrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 20.h),
                children: [
                  if (showListeningCard &&
                      listeningAudioPath != null &&
                      listeningAudioPath!.trim().isNotEmpty) ...[
                    HskExamListeningAudioCard(
                      audioAssetPath: listeningAudioPath!.trim(),
                      isAudioPlaying: isAudioPlaying,
                      audioDuration: audioDuration,
                      audioPosition: audioPosition,
                      onToggleAudio: onToggleAudio,
                      formatDuration: formatDuration,
                    ),
                    SizedBox(height: 12.h),
                  ],
                  ...questionWidgets,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
