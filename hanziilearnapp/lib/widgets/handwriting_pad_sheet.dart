import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/core/constants.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class HandwritingSubmission {
  final String imagePath;
  final Size imageSize;

  const HandwritingSubmission({
    required this.imagePath,
    required this.imageSize,
  });
}

class HandwritingPadSheet extends StatefulWidget {
  const HandwritingPadSheet({super.key});

  @override
  State<HandwritingPadSheet> createState() => _HandwritingPadSheetState();
}

class _HandwritingPadSheetState extends State<HandwritingPadSheet> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  Size _canvasSize = const Size(900, 500);

  bool get _hasInk => _strokes.any((stroke) => stroke.isNotEmpty);

  void _startStroke(DragStartDetails details) {
    setState(() {
      _strokes.add([details.localPosition]);
    });
  }

  void _appendStroke(DragUpdateDetails details) {
    if (_strokes.isEmpty) {
      return;
    }

    setState(() {
      _strokes.last.add(details.localPosition);
    });
  }

  void _clearCanvas() {
    setState(_strokes.clear);
  }

  Future<void> _submit() async {
    if (!_hasInk) {
      Navigator.pop(context);
      return;
    }

    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      image.dispose();
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(
      tempDir.path,
      'handwriting_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await File(filePath).writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    image.dispose();

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      HandwritingSubmission(imagePath: filePath, imageSize: _canvasSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Viết chữ để nhận diện',
              style: TextStyle(
                fontSize: 18.sp,
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Viết rõ từng chữ trên khung bên dưới.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
            ),
            SizedBox(height: 14.h),
            LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = Size(constraints.maxWidth, 280.h);

                return RepaintBoundary(
                  key: _boundaryKey,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _startStroke,
                    onPanUpdate: _appendStroke,
                    onPanEnd: (_) => setState(() {}),
                    child: Container(
                      width: constraints.maxWidth,
                      height: 260.h,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.borderEnable),
                      ),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _HandwritingPainter(strokes: _strokes),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                TextButton(
                  onPressed: _clearCanvas,
                  child: Text(
                    'Xóa',
                    style: TextStyle(color: AppColors.errorText),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Đóng',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
                SizedBox(width: 8.w),
                FilledButton(
                  onPressed: _submit,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(
                      AppColors.vocabularyButton,
                    ),
                  ),
                  child: Text(
                    'Nhận diện',
                    style: TextStyle(color: AppColors.whiteText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HandwritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  const _HandwritingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1.5;
    final strokePaint = Paint()
      ..color = AppColors.primaryText
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      guidePaint,
    );

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          strokePaint.strokeWidth / 2,
          strokePaint,
        );
        continue;
      }

      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);

      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }

      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) {
    return true;
  }
}
