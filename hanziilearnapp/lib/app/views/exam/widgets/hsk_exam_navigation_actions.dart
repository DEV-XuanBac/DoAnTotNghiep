import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HskExamNavigationActions extends StatelessWidget {
  const HskExamNavigationActions({
    super.key,
    required this.canGoPrevious,
    required this.isLastSection,
    required this.onPrevious,
    required this.onNextOrSubmit,
  });

  final bool canGoPrevious;
  final bool isLastSection;
  final VoidCallback onPrevious;
  final VoidCallback onNextOrSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: canGoPrevious ? onPrevious : null,
            child: const Text('Phần trước'),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: ElevatedButton(
            onPressed: onNextOrSubmit,
            child: Text(isLastSection ? 'Nộp bài' : 'Phần tiếp'),
          ),
        ),
      ],
    );
  }
}
