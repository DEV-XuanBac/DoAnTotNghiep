import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hanziilearnapp/app/core/config/api_config.dart';
import 'package:hanziilearnapp/app/core/router/app_router.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/datasource/network_services/google_vision_handwriting_service.dart';
import 'package:hanziilearnapp/app/datasource/network_services/vocabulary_context_ai_service.dart';
import 'package:hanziilearnapp/app/views/home/controllers/home_controller.dart';
import 'package:hanziilearnapp/app/views/home/home_handwriting_recognition.dart';
import 'package:hanziilearnapp/app/views/home/widgets/home_personal_section.dart';
import 'package:hanziilearnapp/app/views/home/widgets/home_result_panel.dart';
import 'package:hanziilearnapp/app/views/home/widgets/home_search_card.dart';
import 'package:hanziilearnapp/app/views/home/widgets/home_suggestion_panel.dart';
import 'package:hanziilearnapp/app/views/home/widgets/home_user_info.dart';
import 'package:hanziilearnapp/app/views/home/widgets/home_utilities_section.dart';
import 'package:hanziilearnapp/widgets/banner_slider.dart';
import 'package:hanziilearnapp/widgets/handwriting_pad_sheet.dart';

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
  static const GoogleVisionHandwritingService _visionOcr =
      GoogleVisionHandwritingService(apiKey: ApiConfig.googleVisionKey);
  static const VocabularyContextAiService _vocabAi = VocabularyContextAiService(
    apiKey: ApiConfig.geminiKey,
  );
  static const HomeHandwritingRecognition _hwRec = HomeHandwritingRecognition(
    _visionOcr,
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
      if (mounted && _ctl.pickedWord?.id == word.id) {
        setState(() {
          _usageLoading = false;
        });
      }
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

  Future<String> _recognizeHandwriting(String imagePath) {
    return _hwRec.recognizeFromImagePath(imagePath, isViMode: _ctl.isViMode);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctl,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: context.palette.backgroundLight,
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                            color: context.palette.errorText,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      SizedBox(height: 8.h),
                      HomeSuggestionPanel(
                        searching: _ctl.searching,
                        searchSubmitted: _ctl.searchSubmitted,
                        searchQuery: _searchCtrl.text,
                        suggestions: _ctl.sugWords,
                        onPickWord: (word) => _ctl.pickWord(
                          word,
                          saveToHistory: false,
                          query: _searchCtrl.text.trim(),
                        ),
                        onSpeakWord: (word) =>
                            unawaited(_speakWord(word.hanzi)),
                      ),
                      SizedBox(height: 12.h),
                      if (_ctl.pickedWord != null)
                        HomeResultPanel(
                          pickedWord: _ctl.pickedWord!,
                          relatedWords: _ctl.relWords,
                          usageWordId: _usageWordId,
                          usageExplain: _usageExplain,
                          usageLoading: _usageLoading,
                          onSpeakPicked: () =>
                              unawaited(_speakWord(_ctl.pickedWord!.hanzi)),
                          onSpeakRelated: (word) =>
                              unawaited(_speakWord(word.hanzi)),
                        ),
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: const BannerSlider(),
                      ),
                      SizedBox(height: 16.h),
                      HomePersonalSection(
                        onlineMins: _ctl.onlineMins,
                        streak: _ctl.streak,
                        checkedDays: _ctl.checkedDays,
                      ),
                      SizedBox(height: 8.h),
                      HomeUtilitiesSection(
                        onConversation: () {
                          if (!_ensureLoggedIn('Vui lòng đăng nhập.')) {
                            return;
                          }
                          unawaited(
                            AppRouter.pushConversationPractice(context),
                          );
                        },
                        onHistory: () {
                          unawaited(
                            AppRouter.pushLookupHistory(
                              context,
                              items: _ctl.history,
                            ),
                          );
                        },
                        onVocabulary: () {
                          if (widget.onRequestTabChange != null) {
                            widget.onRequestTabChange!(2);
                            return;
                          }
                          unawaited(
                            AppRouter.replaceWithMainTab(
                              context,
                              initialIndex: 2,
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
