import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';

class HskExamLoadingState extends StatelessWidget {
  const HskExamLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class HskExamErrorState extends StatelessWidget {
  const HskExamErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp, color: context.palette.secondaryText),
        ),
      ),
    );
  }
}

class HskExamEmptyState extends StatelessWidget {
  const HskExamEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: context.palette.secondaryText,
          ),
        ),
      ),
    );
  }
}
