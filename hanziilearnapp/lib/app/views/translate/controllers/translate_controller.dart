import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hanziilearnapp/app/datasource/local/local_pronunciation_service.dart';
import 'package:hanziilearnapp/app/datasource/network_services/translate_service.dart';
import 'package:lpinyin/lpinyin.dart';

class TranslateController extends ChangeNotifier {
  TranslateController({
    TranslationService? translationService,
    LocalPronunciationService? speechService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _translationService = translationService ?? TranslationService(),
       _speechService = speechService ?? LocalPronunciationService(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final TranslationService _translationService;
  final LocalPronunciationService _speechService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TextEditingController inputController = TextEditingController();

  String translatedText = '';
  String pinyinText = '';
  String? errorMessage;
  String? scannedImagePath;
  Size? imageSize;

  bool isLoading = false;
  bool isImageScanning = false;
  bool isListening = false;
  bool isVietnameseToChinese = true;
  bool _skipNextInputChange = false;
  String _lastTranslationInput = '';
  String _lastTranslationOutput = '';
  String _currentTranslationType = 'chữ viết';

  Timer? _debounceTimer;
  bool _isDisposed = false;

  String get sourceLanguage => isVietnameseToChinese ? 'vi' : 'zh-cn';
  String get targetLanguage => isVietnameseToChinese ? 'zh-cn' : 'vi';
  TextRecognitionScript get recognitionScript {
    return sourceLanguage == 'zh-cn'
        ? TextRecognitionScript.chinese
        : TextRecognitionScript.latin;
  }

  FirebaseFirestore get firestore => _firestore;
  User? get currentUser => _auth.currentUser;

  void initialize() {
    inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _speechService.cancel();
    inputController.dispose();
    super.dispose();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  void _onInputChanged() {
    if (_skipNextInputChange) {
      _skipNextInputChange = false;
      return;
    }

    _debounceTimer?.cancel();
    final text = inputController.text.trim();

    if (text.isEmpty) {
      translatedText = '';
      pinyinText = '';
      errorMessage = null;
      _notify();
      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
      () => translateText(text),
    );
  }

  Future<void> translateText(String text) async {
    isLoading = true;
    errorMessage = null;
    _notify();

    try {
      final result = await _translationService.trText(
        text,
        from: sourceLanguage,
        to: targetLanguage,
      );

      translatedText = result;
      pinyinText = _buildPinyinIfNeeded(result, targetLanguage: targetLanguage);
      isLoading = false;
      _notify();

      await _saveTranslationHistory(
        sourceText: text,
        translatedText: result,
        translationType: 'chữ viết',
      );
    } catch (_) {
      isLoading = false;
      errorMessage = 'Không thể dịch.';
      _notify();
    }
  }

  Future<void> translateRecognizedImageFile(
    String imagePath, {
    Size? overrideImageSize,
    bool showOverlayOnImage = true,
    String translationType = 'hình ảnh',
  }) async {
    isImageScanning = true;
    errorMessage = null;
    _notify();

    final textRecognizer = TextRecognizer(script: recognitionScript);

    try {
      final recognizedText = await textRecognizer.processImage(
        InputImage.fromFilePath(imagePath),
      ); // nhận diện chữ trong ảnh

      if (recognizedText.text.trim().isEmpty) {
        throw const FormatException('Không nhận diện được chữ.');
      }

      final computedImageSize = showOverlayOnImage
          ? (overrideImageSize ?? await _getImageSize(imagePath))
          : null; // tính kích thước ảnh
      final translationResult = 
      await _translationService.trOcr(
        recognizedText,
        from: sourceLanguage,
        to: targetLanguage,
      ); // dịch chữ đã nhận diện

      _skipNextInputChange = true;
      inputController.text = translationResult.sourceText;

      scannedImagePath = showOverlayOnImage ? imagePath : null;
      imageSize = computedImageSize;
      translatedText = translationResult.translatedText;
      pinyinText = _buildPinyinIfNeeded(
        translationResult.translatedText,
        targetLanguage: targetLanguage,
      );
      isImageScanning = false;
      _notify();

      await _saveTranslationHistory(
        sourceText: translationResult.sourceText,
        translatedText: translationResult.translatedText,
        translationType: translationType,
      );
    } on FormatException catch (error) {
      isImageScanning = false;
      errorMessage = error.message;
      _notify();
    } catch (_) {
      isImageScanning = false;
      errorMessage = 'Không thể xử lý ảnh.';
      _notify();
    } finally {
      unawaited(textRecognizer.close());
    }
  }

  Future<void> toggleListening() async {
    if (isListening) {
      await stopListening();
      return;
    }

    try {
      isListening = true;
      errorMessage = null;
      _notify();

      await _speechService.startListen(
        localeId: sourceLanguage == 'vi' ? 'vi-VN' : 'zh-CN',
        onPartialResult: (text) {
          final recognizedWords = text.trim();
          if (recognizedWords.isEmpty) return;
          inputController.value = TextEditingValue(
            text: recognizedWords,
            selection: TextSelection.collapsed(offset: recognizedWords.length),
          );
        },
      );
    } catch (_) {
      isListening = false;
      errorMessage = 'Không thể nhận diện giọng nói.';
      _notify();
    }

  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
    isListening = false;
    _notify();
  }

  Future<void> switchLanguage() async {
    if (isListening) {
      await stopListening();
    }

    isVietnameseToChinese = !isVietnameseToChinese;
    translatedText = '';
    pinyinText = '';
    errorMessage = null;
    scannedImagePath = null;
    imageSize = null;
    _notify();
  }

  void clearImageOverlay() {
    scannedImagePath = null;
    imageSize = null;
    _notify();
  }

  Future<void> _saveTranslationHistory({
    required String sourceText,
    required String translatedText,
    required String translationType,
  }) async {
    final user = _auth.currentUser;
    final normalizedSource = sourceText.trim();
    final normalizedTranslated = translatedText.trim();
    if (user == null || normalizedSource.isEmpty || normalizedTranslated.isEmpty) {
      return;
    }

    if (_lastTranslationInput == normalizedSource &&
        _lastTranslationOutput == normalizedTranslated &&
        _currentTranslationType == translationType) {
      return;
    }

    _lastTranslationInput = normalizedSource;
    _lastTranslationOutput = normalizedTranslated;
    _currentTranslationType = translationType;

    final doc = _firestore.collection('translation_history').doc();
    await doc.set({
      'history_id': doc.id,
      'user_id': user.uid,
      'source_text': normalizedSource,
      'translated_text': normalizedTranslated,
      'translation_type': translationType,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  String _buildPinyinIfNeeded(
    String value, {
    required String targetLanguage,
  }) {
    if (targetLanguage != 'zh-cn' || value.trim().isEmpty) {
      return '';
    }

    return PinyinHelper.getPinyin(
      value,
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
}
