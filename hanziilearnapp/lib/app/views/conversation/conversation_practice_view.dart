import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hanziilearnapp/app/core/config/api_config.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/core/constants/conversation_constants.dart';
import 'package:hanziilearnapp/app/datasource/local/local_pronunciation_service.dart';
import 'package:hanziilearnapp/app/datasource/network_services/conversation_ai_service.dart';
import 'package:hanziilearnapp/app/models/conversation_model.dart';
import 'package:hanziilearnapp/app/models/pronunciation_result.dart';
import 'package:hanziilearnapp/app/views/conversation/widgets/conversation_bottom_bar.dart';
import 'package:hanziilearnapp/app/views/conversation/widgets/conversation_loading_view.dart';
import 'package:hanziilearnapp/app/views/conversation/widgets/conversation_messages_list.dart';
import 'package:hanziilearnapp/app/views/conversation/widgets/conversation_scenario_header.dart';
import 'package:hanziilearnapp/app/views/conversation/widgets/conversation_topic_selection.dart';

/// Màn hình luyện hội thoại tiếng Trung với AI.
/// Luồng: chọn chủ đề → AI sinh hội thoại → TTS → mic → chấm điểm.
class ConversationPracticeView extends StatefulWidget {
  const ConversationPracticeView({super.key});

  @override
  State<ConversationPracticeView> createState() =>
      _ConversationPracticeViewState();
}

class _ConversationPracticeViewState extends State<ConversationPracticeView> {
  static const _ttsDelay = Duration(milliseconds: 400);
  static const _scrollLag = Duration(milliseconds: 200);
  static const _scrollMs = Duration(milliseconds: 300);

  late final ConversationAiService _ai;
  final LocalPronunciationService _speech = LocalPronunciationService();
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scroll = ScrollController();

  ConversationDialogue? _chat;
  bool _loading = false;
  String? _err;
  int _step = 0;
  bool _ttsBusy = false;
  bool _micOn = false;
  bool _scoring = false;
  int _hsk = 1;
  String _live = '';

  /// Điểm phát âm theo chỉ số bước trong hội thoại.
  final Map<int, PronunciationResult> _pron = {};

  @override
  void initState() {
    super.initState();
    _ai = ConversationAiService(apiKey: ApiConfig.geminiKey);
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _ttsBusy = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _onPickTopic(ConversationTopic topic) async {
    if (!ApiConfig.hasGemini) {
      _toast(ConversationConstants.errGeneric);
      return;
    }

    _resetAll(loading: true);

    try {
      final out = await _ai.genDlg(topic: topic, level: _hsk);
      if (mounted) {
        setState(() {
          _chat = out;
          _loading = false;
        });
        _autoTts();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _err = '${ConversationConstants.errGenPrefix} $e';
        });
      }
    }
  }

  Future<void> _speak(String text) async {
    if (_ttsBusy) return;
    setState(() => _ttsBusy = true);
    await _tts.speak(text);
  }

  Future<void> _autoTts() async {
    if (_chat == null) return;
    if (_step >= _chat!.messages.length) return;
    final m = _chat!.messages[_step];
    if (!m.isUserTurn) {
      await Future.delayed(_ttsDelay);
      if (mounted) _speak(m.chinese);
    }
  }

  Future<void> _tapMic() async {
    if (_scoring) return;
    if (_micOn) {
      await _stopMic();
      return;
    }
    await _openMic();
  }

  Future<void> _stopMic() async {
    setState(() {
      _micOn = false;
      _scoring = true;
    });

    try {
      final ref = _chat!.messages[_step].chinese;
      final r = await _speech.stopAssess(ref);

      if (mounted) {
        setState(() {
          _pron[_step] = r;
          _scoring = false;
          _live = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _scoring = false);
        _toast('${ConversationConstants.errAssessPrefix} $e');
      }
    }
  }

  Future<void> _openMic() async {
    try {
      await _speech.startListen(
        onPartialResult: (t) {
          if (mounted) setState(() => _live = t);
        },
      );

      if (!mounted) return;
      setState(() {
        _micOn = true;
        _live = '';
      });
    } catch (e) {
      _toast('${ConversationConstants.errMicPrefix} $e');
    }
  }

  void _next() {
    if (_chat == null) return;
    if (_step < _chat!.messages.length - 1) {
      setState(() => _step++);
      _scrollDown();
      _autoTts();
    }
  }

  void _scrollDown() {
    Future.delayed(_scrollLag, () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: _scrollMs,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _leaveChat() => _resetAll();

  void _resetAll({bool loading = false}) {
    setState(() {
      _loading = loading;
      _chat = null;
      _step = 0;
      _pron.clear();
      _err = null;
      _live = '';
      _micOn = false;
      _scoring = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          ConversationConstants.title,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        actions: [
          if (_chat != null)
            IconButton(
              onPressed: _leaveChat,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: ConversationConstants.topicTip,
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const ConversationLoadingView()
            : _chat == null
            ? ConversationTopicSelection(
                hsk: _hsk,
                err: _err,
                onHsk: (v) => setState(() => _hsk = v),
                onTopic: _onPickTopic,
              )
            : _chatBody(),
      ),
    );
  }

  Widget _chatBody() {
    final c = _chat!;
    final done =
        _step >= c.messages.length - 1 &&
        (_pron.containsKey(_step) || !c.messages[_step].isUserTurn);

    return Column(
      children: [
        ConversationScenarioHeader(chat: c),
        SizedBox(height: 8.h),
        Expanded(
          child: ConversationMessagesList(
            chat: c,
            step: _step,
            pron: _pron,
            scroll: _scroll,
            onPlay: _speak,
          ),
        ),
        ConversationBottomBar(
          step: _step,
          stepMax: c.messages.length,
          scoring: _scoring,
          done: done,
          myTurn: c.messages[_step].isUserTurn,
          hasPron: _pron.containsKey(_step),
          micOn: _micOn,
          live: _live,
          avg10: _avg10(c),
          tapMic: _tapMic,
          onNext: _next,
          newTopic: _leaveChat,
          replay: _restart,
        ),
      ],
    );
  }

  void _restart() {
    setState(() {
      _step = 0;
      _pron.clear();
    });
    _autoTts();
  }

  /// Trung bình điểm các lượt user (thang 10). Lỗi / thiếu điểm = 0.
  double? _avg10(ConversationDialogue c) {
    final idxUser = <int>[];
    for (var i = 0; i < c.messages.length; i++) {
      if (c.messages[i].isUserTurn) idxUser.add(i);
    }
    if (idxUser.isEmpty) return null;

    var sum = 0.0;
    for (final i in idxUser) {
      final r = _pron[i];
      if (r != null && r.errorMessage == null) {
        sum += r.overallScore;
      }
    }
    return (sum / idxUser.length) / 10.0;
  }
}
