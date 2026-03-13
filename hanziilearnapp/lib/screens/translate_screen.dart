import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hanziilearnapp/core/constants.dart';
import 'package:hanziilearnapp/services/translate_service.dart';
import 'package:hanziilearnapp/widgets/handwriting_pad_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TranslationService _translationService = TranslationService();
  final SpeechToText _speechToText = SpeechToText();

  String _translatedText = '';
  String _pinyinText = '';
  String? _errorMessage;
  String? _scannedImagePath;
  Size? _imageSize;

  bool _isLoading = false;
  bool _isImageScanning = false;
  bool _isListening = false;
  bool _isVietnameseToChinese = true;
  bool _skipNextInputChange = false;

  Timer? _debounceTimer;

  String get _sourceLanguage => _isVietnameseToChinese ? 'vi' : 'zh-cn';
  String get _targetLanguage => _isVietnameseToChinese ? 'zh-cn' : 'vi';

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _speechToText.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (_skipNextInputChange) {
      _skipNextInputChange = false;
      return;
    }

    _debounceTimer?.cancel();
    final text = _inputController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _translatedText = '';
        _pinyinText = '';
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
      () => _translateText(text),
    );
  }

  Future<void> _translateText(String text) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final translatedText = await _translationService.translateText(
        text,
        from: _sourceLanguage,
        to: _targetLanguage,
      );

      if (!mounted) return;

      setState(() {
        _translatedText = translatedText;
        _pinyinText = _buildPinyinIfNeeded(
          translatedText,
          targetLanguage: _targetLanguage,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể dịch.';
      });
    }
  }

  Future<void> _scanText(ImageSource source) async {
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

    await _translateRecognizedImageFile(image.path);
  }

  Future<void> _translateRecognizedImageFile(
    String imagePath, {
    Size? overrideImageSize,
    bool showOverlayOnImage = true,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isImageScanning = true;
      _errorMessage = null;
    });

    final textRecognizer = TextRecognizer(script: _recognitionScript);

    try {
      final recognizedText = await textRecognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );

      if (recognizedText.text.trim().isEmpty) {
        throw const FormatException('Không nhận diện được chữ.');
      }

      final imageSize = showOverlayOnImage
          ? (overrideImageSize ?? await _getImageSize(imagePath))
          : null;
      final translationResult = await _translationService
          .translateRecognizedText(
            recognizedText,
            from: _sourceLanguage,
            to: _targetLanguage,
          );

      _skipNextInputChange = true;
      _inputController.text = translationResult.sourceText;

      if (!mounted) return;

      setState(() {
        _scannedImagePath = showOverlayOnImage ? imagePath : null;
        _imageSize = imageSize;
        _translatedText = translationResult.translatedText;
        _pinyinText = _buildPinyinIfNeeded(
          translationResult.translatedText,
          targetLanguage: _targetLanguage,
        );
        _isImageScanning = false;
      });
    } on FormatException catch (error) {
      if (!mounted) return;

      setState(() {
        _isImageScanning = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isImageScanning = false;
        _errorMessage = 'Không thể xử lý ảnh.';
      });
    } finally {
      textRecognizer.close();
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) {
          return;
        }

        final isListening = status == 'listening';
        if (_isListening != isListening) {
          setState(() {
            _isListening = isListening;
          });
        }
      },
      onError: (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isListening = false;
          _errorMessage = 'Không thể nhận diện giọng nói.';
        });
      },
    );

    if (!available) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Thiết bị không hỗ trợ nhận diện giọng nói.';
      });
      return;
    }

    final localeId = await _resolveSpeechLocaleId();

    await _speechToText.listen(
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (result) {
        final recognizedWords = result.recognizedWords.trim();
        if (recognizedWords.isEmpty) {
          return;
        }

        _inputController.value = TextEditingValue(
          text: recognizedWords,
          selection: TextSelection.collapsed(offset: recognizedWords.length),
        );

        if (!mounted) return;

        if (!_isListening) {
          setState(() {
            _isListening = true;
          });
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
    });
  }

  Future<String?> _resolveSpeechLocaleId() async {
    final locales = await _speechToText.locales();
    final systemLocale = await _speechToText.systemLocale();
    final preferredPrefixes = _sourceLanguage == 'vi'
        ? const ['vi', 'en']
        : const ['zh', 'cmn', 'yue'];

    for (final prefix in preferredPrefixes) {
      for (final locale in locales) {
        final localeId = locale.localeId.toLowerCase();
        final name = locale.name.toLowerCase();
        if (localeId.startsWith(prefix) || name.contains(prefix)) {
          return locale.localeId;
        }
      }
    }

    return systemLocale?.localeId;
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

    await _translateRecognizedImageFile(
      submission.imagePath,
      overrideImageSize: submission.imageSize,
      showOverlayOnImage: false,
    );
  }

  TextRecognitionScript get _recognitionScript {
    return _sourceLanguage == 'zh-cn'
        ? TextRecognitionScript.chinese
        : TextRecognitionScript.latin;
  }

  String _buildPinyinIfNeeded(
    String translatedText, {
    required String targetLanguage,
  }) {
    if (targetLanguage != 'zh-cn' || translatedText.trim().isEmpty) {
      return '';
    }

    return PinyinHelper.getPinyin(
      translatedText,
      separator: ' ',
      format: PinyinFormat.WITH_TONE_MARK,
    );
  }

  Future<Size> _getImageSize(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    final size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );

    frame.image.dispose();
    return size;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
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
    if (_scannedImagePath == null || _imageSize == null) {
      return const SizedBox();
    }

    final imageFile = File(_scannedImagePath!);
    final imageWidth = _imageSize!.width;
    final imageHeight = _imageSize!.height;

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
                if (_translatedText.trim().isNotEmpty)
                  _buildOverlaySummary(
                    maxWidth: constraints.maxWidth,
                    maxHeight: height,
                  ),
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _scannedImagePath = null;
                        _imageSize = null;
                      });
                    },
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
      _translatedText,
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
            _translatedText,
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
      maxLines: null,
    )..layout(maxWidth: maxWidth);

    return painter.size.height;
  }

  Widget _buildTranslationContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_translatedText.isEmpty) {
      return Text(
        'Bản dịch',
        style: TextStyle(
          color: AppColors.secondaryText,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pinyinText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(_pinyinText, style: TextStyle(fontSize: 14.sp)),
          ),
        SelectableText(
          _translatedText,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Future<void> _switchLanguage() async {
    if (_isListening) {
      await _stopListening();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isVietnameseToChinese = !_isVietnameseToChinese;
      _translatedText = '';
      _pinyinText = '';
      _errorMessage = null;
      _scannedImagePath = null;
      _imageSize = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Padding(
        padding: EdgeInsets.all(14.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 45.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dịch văn bản',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
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
                  color: AppColors.primaryText,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _inputController,
                maxLines: 6,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: AppColors.primaryText,
                decoration: InputDecoration(
                  hintText: 'Nhập đoạn văn bản...',
                  hintStyle: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.borderDefault,
                      width: 1.w,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Bản dịch',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.borderEnable, width: 1.w),
                ),
                child: _buildTranslationContent(),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 10.h),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppColors.errorText,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_isImageScanning)
                Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.blueDarkText,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Đang nhận diện và dịch...',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              _buildImageOverlay(),
              SizedBox(height: 30.h),
              // Exchange lang & tool button
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.borderDefault,
                    width: 1.w,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 120.w,
                          height: 30.h,
                          decoration: BoxDecoration(
                            color: AppColors.whiteCard,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              _isVietnameseToChinese
                                  ? 'Việt'
                                  : 'Trung (Giản thể)',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _switchLanguage,
                          child: Image.asset(
                            'assets/iconic/exchange_ic.png',
                            width: 22.w,
                            height: 22.h,
                          ),
                        ),
                        Container(
                          width: 120.w,
                          height: 30.h,
                          decoration: BoxDecoration(
                            color: AppColors.whiteCard,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              _isVietnameseToChinese
                                  ? 'Trung (Giản thể)'
                                  : 'Việt',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _toolButton(
                          iconPath: 'assets/iconic/microphone_ic.png',
                          onTap: _toggleListening,
                          isActive: _isListening,
                        ),
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundWhite,
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            child: Image.asset(
                              'assets/iconic/camera_ic.png',
                              width: 30.w,
                              height: 30.h,
                            ),
                          ),
                        ),
                        _toolButton(
                          iconPath: 'assets/iconic/writing_ic.png',
                          onTap: _openHandwritingPad,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton({
    required String iconPath,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blueDarkText : AppColors.toolButton,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(color: AppColors.backgroundWhite, width: 2.w),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.blueDarkText.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Image.asset(
          iconPath,
          width: 28.w,
          height: 28.h,
          color: AppColors.whiteText.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
