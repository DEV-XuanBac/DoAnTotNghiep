import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/datasource/local/local_pronunciation_service.dart';
import 'package:hanziilearnapp/app/models/pronunciation_result.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Màn hình luyện nói theo AI: nghe phát âm chuẩn, thu âm, và nhận điểm đánh giá.
class SpeechPracticeView extends StatefulWidget {
  const SpeechPracticeView({super.key, required this.word});

  final Word word;

  @override
  State<SpeechPracticeView> createState() => _SpeechPracticeViewState();
}

class _SpeechPracticeViewState extends State<SpeechPracticeView> {
  final FlutterTts _tts = FlutterTts();
  final LocalPronunciationService _pronService = LocalPronunciationService();

  bool _isPlaying = false;
  bool _isRecording = false;
  bool _isAssessing = false;
  PronunciationResult? _lastResult;
  String _partialText = '';

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  /// Cấu hình giọng đọc mẫu tiếng Trung.
  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _tts.stop();
    _pronService.dispose();
    super.dispose();
  }

  Future<void> _playReference() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    await _tts.speak(widget.word.hanzi);
    await Future.delayed(const Duration(milliseconds: 500));
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  /// Nút micro hoạt động theo 2 trạng thái:
  /// - đang ghi âm -> dừng và chấm điểm
  /// - chưa ghi âm -> bắt đầu nghe
  Future<void> _toggleRecord() async {
    if (_isAssessing) return;

    if (_isRecording) {
      await _stopAndAssess();
      return;
    }

    try {
      await _pronService.startListening(
        onPartialResult: (text) {
          if (mounted) setState(() => _partialText = text);
        },
      );
      if (mounted) {
        setState(() {
          _isRecording = true;
          _partialText = '';
        });
      }
    } catch (e) {
      _showSnack('Lỗi micro: $e');
    }
  }

  /// Dừng nhận dạng và chấm điểm dựa trên câu mẫu hiện tại.
  Future<void> _stopAndAssess() async {
    setState(() {
      _isRecording = false;
      _isAssessing = true;
      _lastResult = null;
    });

    try {
      final result = await _pronService.stopAndAssess(widget.word.hanzi);
      if (mounted) {
        setState(() {
          _lastResult = result;
          _isAssessing = false;
          _partialText = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAssessing = false);
        _showSnack('Lỗi: $e');
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Luyện nói'),
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWordCard(),
              SizedBox(height: 32.h),
              _buildInstruction(),
              SizedBox(height: 24.h),
              _buildActionButtons(),
              if (_isAssessing) ...[
                SizedBox(height: 24.h),
                const Center(child: CircularProgressIndicator()),
                SizedBox(height: 8.h),
                Text(
                  'AI đang đánh giá phát âm...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14.sp,
                  ),
                ),
              ],
              if (_lastResult != null) ...[
                SizedBox(height: 28.h),
                _buildScoreCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderDefault.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            widget.word.hanzi,
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.word.pinyin,
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            widget.word.meaning,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.vocabDarkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hướng dẫn',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '1. Nhấn loa để nghe phát âm chuẩn\n'
            '2. Nhấn micro để bắt đầu nói\n'
            '3. Đọc to từ tiếng Trung, sau đó nhấn dừng\n'
            '4. AI sẽ đánh giá điểm phát âm của bạn',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.secondaryText,
              height: 1.6,
            ),
          ),
          if (_isRecording && _partialText.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn đang nói:',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _partialText,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blueDarkText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          icon: Icons.volume_up_rounded,
          label: 'Nghe',
          isActive: _isPlaying,
          onTap: _playReference,
        ),
        SizedBox(width: 24.w),
        _RoundButton(
          icon: _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          label: _isRecording ? 'Dừng' : 'Ghi âm',
          isActive: _isRecording,
          onTap: _toggleRecord,
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    final r = _lastResult!;
    if (r.errorMessage != null) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.errorText.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorText, size: 40.sp),
            SizedBox(height: 8.h),
            Text(
              r.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.errorText, fontSize: 14.sp),
            ),
          ],
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
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Điểm tổng',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$overall/100',
            style: TextStyle(
              fontSize: 42.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScoreChip(label: 'Độ chính xác', value: r.accuracyScore),
              _ScoreChip(label: 'Độ trôi chảy', value: r.fluencyScore),
              _ScoreChip(label: 'Độ hoàn chỉnh', value: r.completenessScore),
            ],
          ),
          if (r.prosodyScore != null) ...[
            SizedBox(height: 12.h),
            _ScoreChip(label: 'Ngữ điệu', value: r.prosodyScore!),
          ],
          if (r.displayText.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Bạn nói: ${r.displayText}',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: isActive ? AppColors.blueDarkText : AppColors.toolButton,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isActive ? AppColors.blueDarkText : Colors.grey)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.whiteText, size: 32.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.secondaryText,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value.round().toString(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
