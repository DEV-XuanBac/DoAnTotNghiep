import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hanziilearnapp/app/core/config/api_config.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/datasource/network_services/google_vision_handwriting_service.dart';
import 'package:hanziilearnapp/app/datasource/network_services/vocabulary_context_ai_service.dart';
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:hanziilearnapp/app/views/conversation/conversation_practice_view.dart';
import 'package:hanziilearnapp/app/views/home/controllers/home_controller.dart';
import 'package:hanziilearnapp/app/views/home/lookup_history_view.dart';
import 'package:hanziilearnapp/app/views/home/widgets/home_search_card.dart';
import 'package:hanziilearnapp/app/views/home/widgets/home_user_info.dart';
import 'package:hanziilearnapp/app/views/home/widgets/home_utilities_section.dart';
import 'package:hanziilearnapp/app/views/home/widgets/word_tile.dart';
import 'package:hanziilearnapp/app/views/shell/bottom_nav.dart';
import 'package:hanziilearnapp/widgets/banner_slider.dart';
import 'package:hanziilearnapp/widgets/handwriting_pad_sheet.dart';
import 'package:hanziilearnapp/widgets/week_progress.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.onRequestTabChange});

  final ValueChanged<int>? onRequestTabChange;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final HomeController _ctl = HomeController();
  final FlutterTts _tts = FlutterTts();
  final GoogleVisionHandwritingService _visionOcr =
      GoogleVisionHandwritingService(apiKey: ApiConfig.googleVisionKey);
  final VocabularyContextAiService _vocabAi = VocabularyContextAiService(
    apiKey: ApiConfig.geminiKey,
  );
  Timer? _debounce;
  String _usageExplain = '';
  String _usageWordId = '';
  bool _usageLoading = false;
  static const String _usageNetworkErrMsg =
      'Cần có kết nối mạng để hiển thị phần giải thích.';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    unawaited(_initTts());
    unawaited(_ctl.initialize());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tts.stop();
    unawaited(_ctl.disposeCtrl());
    _ctl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
  }

  Future<void> _speakWord(String hanzi) async {
    final text = hanzi.trim();
    if (text.isEmpty) {
      return;
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    if (_usageExplain.isNotEmpty || _usageWordId.isNotEmpty || _usageLoading) {
      setState(() {
        _usageExplain = '';
        _usageWordId = '';
        _usageLoading = false;
      });
    }
    final keyword = _searchCtrl.text.trim();
    if (keyword.isEmpty) {
      _ctl.clearSearch();
      return;
    }
    _ctl.clearSubmittedFlag();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _ctl.loadSuggestions(keyword),
    );
  }

  Future<void> _onSearchPressed() async {
    final keyword = _searchCtrl.text.trim();
    final ok = await _ctl.submit(keyword);
    if (!ok) {
      return;
    }
    final word = _ctl.sugWords.first;
    await _ctl.pickWord(word, saveToHistory: true, query: keyword);

    if (!ApiConfig.hasGemini) {
      return;
    }
    setState(() {
      _usageLoading = true;
      _usageExplain = '';
      _usageWordId = word.id;
    });
    try {
      final explain = await _vocabAi
          .explainUsage(word: word, userQuery: keyword)
          .timeout(const Duration(seconds: 20));
      if (!mounted || _ctl.pickedWord?.id != word.id) {
        return;
      }
      setState(() {
        _usageExplain = explain;
      });
    } on TimeoutException {
      if (!mounted || _ctl.pickedWord?.id != word.id) {
        return;
      }
      setState(() {
        _usageExplain = _usageNetworkErrMsg;
      });
    } on SocketException {
      if (!mounted || _ctl.pickedWord?.id != word.id) {
        return;
      }
      setState(() {
        _usageExplain = _usageNetworkErrMsg;
      });
    } catch (e) {
      if (!mounted || _ctl.pickedWord?.id != word.id) {
        return;
      }
      final msg = e.toString().toLowerCase();
      final isNetworkIssue =
          msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('timed out') ||
          msg.contains('timeout') ||
          msg.contains('connection');
      setState(() {
        _usageExplain = isNetworkIssue ? _usageNetworkErrMsg : '';
      });
    } finally {
      if (!mounted || _ctl.pickedWord?.id != word.id) {
        return;
      }
      setState(() {
        _usageLoading = false;
      });
    }
  }

  Future<void> _toggleListening() async {
    await _ctl.toggleMic(
      onRecognizedText: (text) {
        _searchCtrl.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
    );
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

    await _ctl.setHandwritingBusy(true);
    _ctl.setErr(null);

    try {
      final text = await _recognizeHandwriting(submission.imagePath);
      if (text.isEmpty) {
        throw const FormatException('Không nhận diện được mặt chữ');
      }
      _searchCtrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } catch (_) {
      _ctl.setErr('Không nhận diện được mặt chữ');
    } finally {
      await _ctl.setHandwritingBusy(false);
    }
  }

  Future<String> _recognizeHandwriting(String imagePath) async {
    final isViMode = _ctl.isViMode;
    if (_visionOcr.isEnabled) {
      try {
        final cloudText = await _visionOcr.recognizeFromImagePath(
          imagePath,
          isViMode: isViMode,
        );
        final normalized = _normalizeHwQuery(cloudText, isViMode: isViMode);
        if (normalized.isNotEmpty) {
          return normalized;
        }
      } catch (_) {}
    }

    final recognizer = TextRecognizer(
      script: isViMode
          ? TextRecognitionScript.latin
          : TextRecognitionScript.chinese,
    );
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return _extractHwQuery(result, isViMode: isViMode);
    } finally {
      recognizer.close();
    }
  }

  String _extractHwQuery(RecognizedText recognized, {required bool isViMode}) {
    final lines = recognized.blocks
        .expand((block) => block.lines)
        .map((line) => line.text.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return '';
    }

    if (isViMode) {
      final merged = lines.join(' ');
      return _normalizeHwQuery(merged, isViMode: true);
    }

    final merged = lines.join('');
    return _normalizeHwQuery(merged, isViMode: false);
  }

  String _normalizeHwQuery(String raw, {required bool isViMode}) {
    if (isViMode) {
      return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return raw
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\p{Script=Han}a-zA-Z0-9]', unicode: true), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>().isDarkMode;
    return ListenableBuilder(
      listenable: _ctl,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Positioned(
                      child: ClipRRect(
                        child: Image.asset(
                          'assets/logo/bg_home.jpg',
                          fit: BoxFit.fill,
                          width: double.infinity,
                          height: 230.h,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 175.h,
                      left: 10.w,
                      child: const HomeUserInfo(),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeSearchCard(
                        textCtrl: _searchCtrl,
                        isViMode: _ctl.isViMode,
                        listening: _ctl.listening,
                        handwritingBusy: _ctl.handwritingBusy,
                        onSearch: _onSearchPressed,
                        onToggleMic: _toggleListening,
                        onHandwriting: _openHandwritingPad,
                        onToggleMode: (isVi) async {
                          if (_ctl.listening) {
                            await _ctl.toggleMic(onRecognizedText: (_) {});
                          }
                          _ctl.setViMode(isVi);
                        },
                      ),
                      if (_ctl.errMsg != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          _ctl.errMsg!,
                          style: TextStyle(
                            color: AppColors.errorText,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      SizedBox(height: 8.h),
                      _buildSuggestionPanel(),
                      SizedBox(height: 12.h),
                      _buildResultPanel(),
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: BannerSlider(),
                      ),
                      SizedBox(height: 16.h),
                      _buildPersonalSection(),
                      SizedBox(height: 8.h),
                      HomeUtilitiesSection(
                        onConversation: () {
                          if (!_ensureLoggedIn('Vui lòng đăng nhập.')) {
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ConversationPracticeView(),
                            ),
                          );
                        },
                        onHistory: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LookupHistoryView(items: _ctl.history),
                            ),
                          );
                        },
                        onVocabulary: () {
                          if (widget.onRequestTabChange != null) {
                            widget.onRequestTabChange!(2);
                            return;
                          }
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BottomNav(initialIndex: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionPanel() {
    if (_ctl.searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ctl.searchSubmitted) {
      return const SizedBox.shrink();
    }
    if (_searchCtrl.text.trim().isEmpty || _ctl.sugWords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gợi ý từ vựng',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          ..._ctl.sugWords.take(6).map((word) {
            return InkWell(
              onTap: () => _ctl.pickWord(
                word,
                saveToHistory: false,
                query: _searchCtrl.text.trim(),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: WordTile(
                  word: word,
                  onSpeak: () => unawaited(_speakWord(word.hanzi)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    if (_ctl.pickedWord == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết quả từ vựng',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          WordTile(
            word: _ctl.pickedWord!,
            onSpeak: () => unawaited(_speakWord(_ctl.pickedWord!.hanzi)),
          ),
          if (_usageWordId == _ctl.pickedWord!.id &&
              (_usageLoading || _usageExplain.isNotEmpty)) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.lightCardBackground.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: _usageLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Đang tải...',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _usageExplain,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.45,
                        color: AppColors.primaryText,
                      ),
                    ),
            ),
          ],
          if (_ctl.relWords.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              'Từ liên quan',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: 4.h),
            ..._ctl.relWords.take(8).map((word) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: WordTile(
                  word: word,
                  onSpeak: () => unawaited(_speakWord(word.hanzi)),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Cá nhân',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 8.h),
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.cardPersonal,
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50.r),
                    child: Image.asset(
                      'assets/logo/friend_logo.png',
                      width: 72.w,
                      height: 72.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuỗi duy trì đăng nhập',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Đã online được ${_ctl.onlineMins} phút',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryText.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Row(
                    children: [
                      Text(
                        '${_ctl.streak}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 34.sp,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: WeekProgress(checkedDayIndexes: _ctl.checkedDays),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _ensureLoggedIn(String message) {
    if (FirebaseAuth.instance.currentUser != null) {
      return true;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return false;
  }
}
