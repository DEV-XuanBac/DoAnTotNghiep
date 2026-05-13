import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

class HskExamSortSentencesCard extends StatefulWidget {
  const HskExamSortSentencesCard({
    super.key,
    required this.question,
    required this.selectedOrderKey,
    required this.onOrderChanged,
  });

  final HskExamQuestion question;
  final String? selectedOrderKey;
  final ValueChanged<String> onOrderChanged;

  @override
  State<HskExamSortSentencesCard> createState() => _HskExamSortSentencesCardState();
}

class _HskExamSortSentencesCardState extends State<HskExamSortSentencesCard> {
  late List<int> _order;

  @override
  void initState() {
    super.initState();
    _order = List<int>.generate(widget.question.options.length, (i) => i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onOrderChanged(_encodeOrder(_order));
    });
  }

  @override
  void didUpdateWidget(covariant HskExamSortSentencesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId) {
      _order = List<int>.generate(widget.question.options.length, (i) => i);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        widget.onOrderChanged(_encodeOrder(_order));
      });
    }
  }

  String _labelForIndex(int optionIndex) {
    final raw = widget.question.options[optionIndex];
    final colon = raw.indexOf(':');
    if (colon <= 0) {
      return raw.trim().toUpperCase();
    }
    return raw.substring(0, colon).trim().toUpperCase();
  }

  String _encodeOrder(List<int> order) {
    return order.map(_labelForIndex).join('-');
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });
    widget.onOrderChanged(_encodeOrder(_order));
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
              'Câu ${q.questionId} (${q.code}) — Sắp xếp câu',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.palette.primaryText,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Kéo thả để sắp xếp các câu theo đúng thứ tự (từ trên xuống dưới).',
              style: TextStyle(fontSize: 12.sp, color: context.palette.secondaryText),
            ),
            SizedBox(height: 10.h),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _order.length,
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final optionIndex = _order[index];
                final line = q.options[optionIndex];
                return Card(
                  key: ValueKey('${q.questionId}_$optionIndex'),
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
                      line,
                      style: TextStyle(fontSize: 13.sp, color: context.palette.primaryText),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle_rounded, color: context.palette.secondaryText),
                    ),
                  ),
                );
              },
            ),
            if (widget.selectedOrderKey != null && widget.selectedOrderKey!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                'Thứ tự hiện tại: ${widget.selectedOrderKey}',
                style: TextStyle(fontSize: 11.sp, color: context.palette.secondaryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
