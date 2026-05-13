import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/router/app_router.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/views/translate/controllers/translate_controller.dart';
import 'package:hanziilearnapp/app/views/translate/widgets/translate_language_tools.dart';
import 'package:hanziilearnapp/app/views/translate/widgets/translate_result_card.dart';
import 'package:hanziilearnapp/app/views/translate/widgets/translation_history_sheet.dart';
import 'package:hanziilearnapp/widgets/handwriting_pad_sheet.dart';
import 'package:image_picker/image_picker.dart';

class TranslateView extends StatefulWidget {
  const TranslateView({super.key});

  @override
  State<TranslateView> createState() => _TranslateViewState();
}

class _TranslateViewState extends State<TranslateView> {
  late final TranslateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TranslateController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scanText(ImageSource source) async {
    if (source == ImageSource.camera) {
      final capturedPath = await AppRouter.pushCamera(context);
      if (capturedPath == null || capturedPath.trim().isEmpty) {
        return;
      }
      await _controller.translateRecognizedImageFile(capturedPath);
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 2560,
      maxHeight: 2560,
      imageQuality: 95,
    );

    if (image == null) {
      return;
    }
    await _controller.translateRecognizedImageFile(image.path);
  }

  Future<void> _openHandwritingPad() async {
    final submission = await showModalBottomSheet<HandwritingSubmission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HandwritingPadSheet(),
    );

    if (submission == null) {
      return;
    }

    await _controller.translateRecognizedImageFile(
      submission.imagePath,
      overrideImageSize: submission.imageSize,
      showOverlayOnImage: false,
      translationType: 'nét vẽ',
    );
  }

  void _showTranslationHistorySheet() {
    final user = _controller.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để xem lịch sử dịch.'),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.backgroundWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => TranslationHistorySheet(
        firestore: _controller.firestore,
        userId: user.uid,
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _scanText(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _scanText(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOverlay() {
    if (_controller.scannedImagePath == null || _controller.imageSize == null) {
      return const SizedBox();
    }

    final imageFile = File(_controller.scannedImagePath!);
    final imageWidth = _controller.imageSize!.width;
    final imageHeight = _controller.imageSize!.height;

    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = constraints.maxWidth / imageWidth;
          final height = imageHeight * scale;

          return SizedBox(
            width: constraints.maxWidth,
            height: height,
            child: Stack(
              children: [
                Image.file(
                  imageFile,
                  width: constraints.maxWidth,
                  height: height,
                  fit: BoxFit.fill,
                ),
                if (_controller.translatedText.trim().isNotEmpty)
                  _buildOverlaySummary(
                    maxWidth: constraints.maxWidth,
                    maxHeight: height,
                  ),
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: GestureDetector(
                    onTap: _controller.clearImageOverlay,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverlaySummary({
    required double maxWidth,
    required double maxHeight,
  }) {
    final horizontalPadding = 12.w;
    final verticalPadding = 12.h;
    final width = math.max(80.0, maxWidth - horizontalPadding * 2);
    final fontSize = 14.sp;
    final textHeight = _measureTextHeight(
      _controller.translatedText,
      maxWidth: math.max(32.0, width - 16.w),
      fontSize: fontSize,
    );
    final overlayHeight = math.min(
      math.max(80.h, textHeight + 18.h),
      math.max(80.h, maxHeight - verticalPadding * 2),
    );

    return Positioned(
      left: horizontalPadding,
      top: verticalPadding,
      width: width,
      height: overlayHeight,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: SingleChildScrollView(
          child: Text(
            _controller.translatedText,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.black87,
              fontSize: fontSize,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  double _measureTextHeight(
    String text, {
    required double maxWidth,
    required double fontSize,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return painter.size.height;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: context.palette.backgroundLight,
          body: Padding(
            padding: EdgeInsets.all(14.w),
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  SizedBox(height: 45.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dịch văn bản',
                        style: TextStyle(
                          color: context.palette.primaryText,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showTranslationHistorySheet,
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: context.palette.backgroundDark,
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Image.asset(
                            'assets/iconic/arrow_ic.png',
                            width: 18.w,
                            height: 18.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(height: 20.h),
                  Text(
                    'Văn bản gốc',
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _controller.inputController,
                    maxLines: 6,
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: context.palette.primaryText,
                    decoration: InputDecoration(
                      hintText: 'Nhập đoạn văn bản...',
                      hintStyle: TextStyle(
                        color: context.palette.secondaryText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: context.palette.backgroundWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: context.palette.borderDefault,
                          width: 1.w,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Bản dịch',
                    style: TextStyle(
                      color: context.palette.primaryText,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TranslateResultCard(
                    isLoading: _controller.isLoading,
                    translatedText: _controller.translatedText,
                    pinyinText: _controller.pinyinText,
                  ),
                  if (_controller.errorMessage != null) ...[
                    SizedBox(height: 10.h),
                    Text(
                      _controller.errorMessage!,
                      style: TextStyle(
                        color: context.palette.errorText,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_controller.isImageScanning)
                    Padding(
                      padding: EdgeInsets.only(top: 20.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.palette.blueDarkText,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Đang nhận diện và dịch...',
                            style: TextStyle(
                              color: context.palette.secondaryText,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildImageOverlay(),
                  SizedBox(height: 30.h),
                  TranslateLanguageTools(
                    isVietnameseToChinese: _controller.isVietnameseToChinese,
                    isListening: _controller.isListening,
                    onSwitchLanguage: _controller.switchLanguage,
                    onToggleListening: _controller.toggleListening,
                    onPickImage: _showImageSourceDialog,
                    onOpenHandwritingPad: _openHandwritingPad,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
