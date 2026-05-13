import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

class HskExamSortWordCard extends StatefulWidget {
  const HskExamSortWordCard({
    super.key,
    required this.question,
    required this.selectedSentence,
    required this.onSentenceChanged,
  });

  final HskExamQuestion question;
  final String? selectedSentence;
  final ValueChanged<String> onSentenceChanged;

  @override
  State<HskExamSortWordCard> createState() => _HskExamSortWordCardState();
}

class _HskExamSortWordCardState extends State<HskExamSortWordCard> {
  late List<int> _order;
  late List<String> _tokens;

  List<String> _splitTokens(String text) {
    return text
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tokens = _splitTokens(widget.question.questionText);
    _order = List<int>.generate(_tokens.length, (i) => i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onSentenceChanged(_composeSentence());
    });
  }

  @override
  void didUpdateWidget(covariant HskExamSortWordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId) {
      _tokens = _splitTokens(widget.question.questionText);
      _order = List<int>.generate(_tokens.length, (i) => i);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        widget.onSentenceChanged(_composeSentence());
      });
    }
  }

  String _composeSentence() {
    return _order.map((i) => _tokens[i]).join();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });
    widget.onSentenceChanged(_composeSentence());
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: context.palette.backgroundWhite,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: context.palette.borderDefault.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu ${q.questionId} (${q.code}) — Sắp xếp từ thành câu',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.palette.primaryText,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Kéo thả các từ để tạo một câu hoàn chỉnh.',
              style: TextStyle(fontSize: 12.sp, color: context.palette.secondaryText),
            ),
            SizedBox(height: 10.h),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _order.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final tokenIndex = _order[index];
                final word = _tokens[tokenIndex];
                return Card(
                  key: ValueKey('${q.questionId}_w$tokenIndex'),
                  margin: EdgeInsets.only(bottom: 8.h),
                  elevation: 0,
                  color: context.palette.lightCardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: BorderSide(
                      color: context.palette.borderDefault.withValues(alpha: 0.8),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    title: Text(
                      word,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: context.palette.primaryText,
                      ),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle_rounded, color: context.palette.secondaryText),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 6.h),
            Text(
              'Câu của bạn: ${widget.selectedSentence?.isNotEmpty == true ? widget.selectedSentence : '…'}',
              style: TextStyle(fontSize: 12.sp, color: context.palette.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
