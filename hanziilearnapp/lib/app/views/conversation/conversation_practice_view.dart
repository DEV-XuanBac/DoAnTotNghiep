import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hanziilearnapp/app/core/config/api_config.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/datasource/local/local_pronunciation_service.dart';
import 'package:hanziilearnapp/app/datasource/network_services/conversation_ai_service.dart';
import 'package:hanziilearnapp/app/models/conversation_model.dart';
import 'package:hanziilearnapp/app/models/pronunciation_result.dart';

/// Màn hình luyện hội thoại tiếng Trung với AI.
/// Luồng:
/// 1. Chọn chủ đề → AI sinh đoạn hội thoại
/// 2. Phát âm mẫu từng câu qua TTS
/// 3. Người dùng nói khi đến lượt (speech_to_text nhận dạng)
/// 4. So sánh văn bản → chấm điểm phát âm
class ConversationPracticeView extends StatefulWidget {
  const ConversationPracticeView({super.key});

  @override
  State<ConversationPracticeView> createState() =>
      _ConversationPracticeViewState();
}

class _ConversationPracticeViewState
    extends State<ConversationPracticeView> {
  static const _autoPlayDelay = Duration(milliseconds: 400);
  static const _scrollDelay = Duration(milliseconds: 200);
  static const _scrollAnimDuration = Duration(milliseconds: 300);

  late final ConversationAiService _aiService;
  final LocalPronunciationService _pronService = LocalPronunciationService();
  final FlutterTts _tts = FlutterTts();
  final ScrollController _scrollController = ScrollController();

  // State
  ConversationDialogue? _dialog;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 0;
  bool _isSpeaking = false;
  bool _isRecording = false;
  bool _isAssessing = false;
  int _selectedLevel = 1;
  String _partialText = '';

  // Per-message pronunciation scores
  final Map<int, PronunciationResult> _scores = {};

  @override
  void initState() {
    super.initState();
    _aiService = ConversationAiService(apiKey: ApiConfig.geminiApiKey);
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _pronService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // AI dialogue generation
  /// Sinh đoạn hội thoại mới theo chủ đề/HSK và reset toàn bộ tiến trình luyện.
  Future<void> _generateDialogue(ConversationTopic topic) async {
    if (!ApiConfig.isGeminiConfigured) {
      _showSnack('Có lỗi xảy ra, thử lại sau');
      return;
    }

    _resetPracticeState(isLoading: true);

    try {
      final dialog = await _aiService.generateDialogue(
        topic: topic,
        level: _selectedLevel,
      );
      if (mounted) {
        setState(() {
          _dialog = dialog;
          _isLoading = false;
        });
        _autoPlayCurrentStep();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tạo hội thoại: $e';
        });
      }
    }
  }

  //TTS
  /// Đọc câu tiếng Trung hiện tại bằng TTS.
  Future<void> _speakChinese(String text) async {
    if (_isSpeaking) return;
    setState(() => _isSpeaking = true);
    await _tts.speak(text);
  }

  Future<void> _autoPlayCurrentStep() async {
    if (_dialog == null) return;
    if (_currentStep >= _dialog!.messages.length) return;
    final msg = _dialog!.messages[_currentStep];
    if (!msg.isUserTurn) {
      await Future.delayed(_autoPlayDelay);
      if (mounted) _speakChinese(msg.chinese);
    }
  }

  // Speech Recognition & Assessment
  Future<void> _toggleRecord() async {
    if (_isAssessing) return;
    if (_isRecording) {
      await _stopAndAssess();
      return;
    }

    await _startListening();
  }

  Future<void> _stopAndAssess() async {
    setState(() {
      _isRecording = false;
      _isAssessing = true;
    });

    try {
      final ref = _dialog!.messages[_currentStep].chinese;
      final result = await _pronService.stopAndAssess(ref);

      if (mounted) {
        setState(() {
          _scores[_currentStep] = result;
          _isAssessing = false;
          _partialText = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssessing = false);
        _showSnack('Lỗi đánh giá: $e');
      }
    }
  }

  Future<void> _startListening() async {
    try {
      await _pronService.startListening(
        onPartialResult: (text) {
          if (mounted) setState(() => _partialText = text);
        },
      );

      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _partialText = '';
      });
    } catch (e) {
      _showSnack('Lỗi micro: $e');
    }
  }

  void _goNextStep() {
    if (_dialog == null) return;
    if (_currentStep < _dialog!.messages.length - 1) {
      setState(() => _currentStep++);
      _scrollToBottom();
      _autoPlayCurrentStep();
    }
  }

  void _scrollToBottom() {
    Future.delayed(_scrollDelay, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: _scrollAnimDuration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _resetDialog() {
    _resetPracticeState();
  }

  /// Reset trạng thái buổi luyện để bắt đầu phiên mới.
  void _resetPracticeState({bool isLoading = false}) {
    setState(() {
      _isLoading = isLoading;
      _dialog = null;
      _currentStep = 0;
      _scores.clear();
      _errorMessage = null;
      _partialText = '';
      _isRecording = false;
      _isAssessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Luyện hội thoại AI',
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
          if (_dialog != null)
            IconButton(
              onPressed: _resetDialog,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Chọn chủ đề khác',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _dialog == null
            ? _buildTopicSelection()
            : _buildConversation(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            'AI đang tạo đoạn hội thoại...',
            style: TextStyle(fontSize: 16.sp, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  // ── Topic Selection ──
  Widget _buildTopicSelection() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn chủ đề hội thoại',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'AI sẽ tạo một đoạn hội thoại mẫu để bạn luyện nói',
            style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
          ),
          SizedBox(height: 12.h),

          // HSK level selector
          _buildLevelSelector(),
          SizedBox(height: 14.h),

          if (_errorMessage != null) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.errorText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: AppColors.errorText, fontSize: 13.sp),
              ),
            ),
            SizedBox(height: 12.h),
          ],

          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 1.5,
              ),
              itemCount: ConversationAiService.availableTopics.length,
              itemBuilder: (_, i) {
                final topic = ConversationAiService.availableTopics[i];
                return _buildTopicCard(topic);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.borderDefault.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Trình độ:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(6, (i) {
                  final lvl = i + 1;
                  final selected = lvl == _selectedLevel;
                  return Padding(
                    padding: EdgeInsets.only(right: 6.w),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLevel = lvl),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.darkBlueCard
                              : AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: selected
                                ? AppColors.darkBlueCard
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Text(
                          'HSK$lvl',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.whiteText
                                : AppColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(ConversationTopic topic) {
    return GestureDetector(
      onTap: () => _generateDialogue(topic),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.darkBlueCard.withValues(alpha: 0.85),
              AppColors.darkGreenCard.withValues(alpha: 0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBlueCard.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(topic.icon, style: TextStyle(fontSize: 30.sp)),
            SizedBox(height: 6.h),
            Text(
              topic.nameCn,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteText,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              topic.nameVi,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.whiteText.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversation() {
    final d = _dialog!;
    final isFinished =
        _currentStep >= d.messages.length - 1 &&
        (_scores.containsKey(_currentStep) ||
            !d.messages[_currentStep].isUserTurn);

    return Column(
      children: [
        // Scenario header
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.lightCardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${d.topicChinese} - ${d.topicVietnamese}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                d.scenario,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),

        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: _currentStep + 1,
            itemBuilder: (_, i) => _buildMessageBubble(i),
          ),
        ),

        // Bottom action bar
        _buildBottomBar(isFinished),
      ],
    );
  }

  Widget _buildMessageBubble(int index) {
    final msg = _dialog!.messages[index];
    final isUser = msg.isUserTurn;
    final isCurrent = index == _currentStep;
    final score = _scores[index];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar('AI', AppColors.darkBlueCard),
          if (!isUser) SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Speaker label
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    isUser ? 'Bạn' : 'Đối tác',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Message card
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.darkBlueCard.withValues(alpha: 0.1)
                        : AppColors.backgroundWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 16.r : 4.r),
                      topRight: Radius.circular(isUser ? 4.r : 16.r),
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: Radius.circular(16.r),
                    ),
                    border: isCurrent
                        ? Border.all(
                            color: AppColors.darkBlueCard.withValues(
                              alpha: 0.5,
                            ),
                            width: 1.5,
                          )
                        : Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Chinese text
                      Text(
                        msg.chinese,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Pinyin
                      Text(
                        msg.pinyin,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.blueDarkText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Vietnamese
                      Text(
                        msg.vietnamese,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.secondaryText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      // Play button
                      SizedBox(height: 6.h),
                      GestureDetector(
                        onTap: () => _speakChinese(msg.chinese),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              size: 18.sp,
                              color: AppColors.toolButton,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Nghe',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.toolButton,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Score display for user messages
                if (isUser && score != null) _buildInlineScore(score),
              ],
            ),
          ),
          if (isUser) SizedBox(width: 8.w),
          if (isUser) _buildAvatar('B', AppColors.greenCard),
        ],
      ),
    );
  }

  Widget _buildAvatar(String label, Color color) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.whiteText,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInlineScore(PronunciationResult r) {
    if (r.errorMessage != null) {
      return Padding(
        padding: EdgeInsets.only(top: 6.h),
        child: Text(
          'Lỗi: ${r.errorMessage}',
          style: TextStyle(color: AppColors.errorText, fontSize: 12.sp),
        ),
      );
    }

    final overall = r.overallScore.round();
    final color = overall >= 80
        ? AppColors.greenText
        : overall >= 60
        ? AppColors.blueDarkText
        : AppColors.errorText;

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overall >= 80
                ? Icons.emoji_events_rounded
                : overall >= 60
                ? Icons.thumb_up_alt_rounded
                : Icons.refresh_rounded,
            color: color,
            size: 18.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            'Điểm: $overall/100',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'CX:${r.accuracyScore.round()} TC:${r.fluencyScore.round()} HT:${r.completenessScore.round()}',
            style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isFinished) {
    final msg = _dialog!.messages[_currentStep];
    final isUserTurn = msg.isUserTurn;
    final hasScore = _scores.containsKey(_currentStep);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Row(
            children: [
              Text(
                'Bước ${_currentStep + 1}/${_dialog!.messages.length}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _dialog!.messages.length,
                    backgroundColor: AppColors.borderDefault.withValues(
                      alpha: 0.45,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.darkBlueCard,
                    ),
                    minHeight: 6.h,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          if (_isAssessing)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8.w),
                Text(
                  'AI đang đánh giá phát âm...',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            )
          else if (isFinished)
            _buildFinishedBar()
          else if (isUserTurn && !hasScore)
            _buildRecordBar()
          else
            _buildNextBar(),
        ],
      ),
    );
  }

  Widget _buildRecordBar() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isRecording
                    ? 'Đang nghe... Nhấn để dừng'
                    : 'Đến lượt bạn! Nhấn micro để nói',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: _isRecording
                      ? AppColors.errorText
                      : AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isRecording && _partialText.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    _partialText,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.blueDarkText,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _toggleRecord,
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: _isRecording
                  ? AppColors.errorText
                  : AppColors.darkBlueCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (_isRecording
                              ? AppColors.errorText
                              : AppColors.darkBlueCard)
                          .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: AppColors.whiteText,
              size: 28.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextBar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _goNextStep,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Tiếp theo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkBlueCard,
          foregroundColor: AppColors.whiteText,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedBar() {
    final userScores = _scores.values
        .where((r) => r.errorMessage == null)
        .toList();
    final avg = userScores.isEmpty
        ? 0.0
        : userScores.map((r) => r.overallScore).reduce((a, b) => a + b) /
              userScores.length;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.greenCard.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.greenCard,
                size: 28.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoàn thành hội thoại!',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    if (userScores.isNotEmpty)
                      Text(
                        'Điểm trung bình: ${avg.round()}/100',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetDialog,
                icon: const Icon(Icons.topic_rounded),
                label: const Text('Chủ đề khác'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkBlueCard,
                  side: BorderSide(color: AppColors.darkBlueCard),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _scores.clear();
                  });
                  _autoPlayCurrentStep();
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Luyện lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlueCard,
                  foregroundColor: AppColors.whiteText,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
