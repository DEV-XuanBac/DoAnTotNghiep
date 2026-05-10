import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
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
  final List<List<Offset>> _strokes = [];
  Size _canvasSize = const Size(900, 500);
  Rect? _inkBounds;

  bool get _hasInk => _strokes.any((stroke) => stroke.isNotEmpty);

  void _startStroke(DragStartDetails details) {
    setState(() {
      final point = details.localPosition;
      _strokes.add([point]);
      _expandInkBounds(point);
    });
  }

  void _appendStroke(DragUpdateDetails details) {
    if (_strokes.isEmpty) {
      return;
    }

    setState(() {
      final point = details.localPosition;
      _strokes.last.add(point);
      _expandInkBounds(point);
    });
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _inkBounds = null;
    });
  }

  Future<void> _submit() async {
    if (!_hasInk) {
      Navigator.pop(context);
      return;
    }

    final bytes = await _buildNormalizedHandwritingBytes();
    if (bytes == null) {
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(
      tempDir.path,
      'handwriting_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await File(filePath).writeAsBytes(
      bytes,
      flush: true,
    );

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

  void _expandInkBounds(Offset point) {
    final dotRect = Rect.fromCircle(center: point, radius: 6);
    _inkBounds = _inkBounds == null ? dotRect : _inkBounds!.expandToInclude(dotRect);
  }

  Future<List<int>?> _buildNormalizedHandwritingBytes() async {
    final bounds = _inkBounds;
    if (bounds == null) {
      return null;
    }

    const outputSize = 1024.0;
    const padding = 110.0;
    const strokeWidth = 36.0;

    final clippedBounds = Rect.fromLTRB(
      bounds.left.clamp(0.0, _canvasSize.width),
      bounds.top.clamp(0.0, _canvasSize.height),
      bounds.right.clamp(0.0, _canvasSize.width),
      bounds.bottom.clamp(0.0, _canvasSize.height),
    );
    final contentWidth = clippedBounds.width <= 0 ? 1.0 : clippedBounds.width;
    final contentHeight = clippedBounds.height <= 0 ? 1.0 : clippedBounds.height;
    final drawableSize = outputSize - (padding * 2);
    final scale = (drawableSize / contentWidth < drawableSize / contentHeight)
        ? drawableSize / contentWidth
        : drawableSize / contentHeight;
    final offsetX = (outputSize - (contentWidth * scale)) / 2 - (clippedBounds.left * scale);
    final offsetY =
        (outputSize - (contentHeight * scale)) / 2 - (clippedBounds.top * scale);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, outputSize, outputSize),
      Paint()..color = Colors.white,
    );

    final strokePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.isEmpty) {
        continue;
      }
      if (stroke.length == 1) {
        final point = _transformPoint(stroke.first, scale, offsetX, offsetY);
        canvas.drawCircle(point, strokeWidth / 2, strokePaint);
        continue;
      }

      final path = Path();
      final first = _transformPoint(stroke.first, scale, offsetX, offsetY);
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i < stroke.length; i++) {
        final p = _transformPoint(stroke[i], scale, offsetX, offsetY);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, strokePaint);
    }

    final image = await recorder.endRecording().toImage(
      outputSize.toInt(),
      outputSize.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      return null;
    }
    return byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }

  Offset _transformPoint(Offset source, double scale, double dx, double dy) {
    return Offset(source.dx * scale + dx, source.dy * scale + dy);
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
