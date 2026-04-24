import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

class ReviewTab extends StatefulWidget {
  const ReviewTab({
    super.key,
    required this.words,
    required this.hskLevel,
    required this.topic,
    required this.isCompleted,
    required this.savedResult,
    required this.onComplete,
    required this.onPlayAudio,
  });

  final List<Word> words;
  final String hskLevel;
  final String topic;
  final bool isCompleted;
  final Map<String, dynamic>? savedResult;
  final Future<void> Function({
    required int totalQuestions,
    required int correctAnswers,
    required List<Map<String, dynamic>> wrongItems,
    required List<Map<String, dynamic>> reviewedWords,
  }) onComplete;
  final Future<void> Function(Word word) onPlayAudio;

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

enum _ReviewGameType { synonymPair, matchMeaning, fillBlank }

class _WrongReviewItem {
  const _WrongReviewItem({
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
  });

  final String question;
  final String userAnswer;
  final String correctAnswer;
}

class _ReviewTabState extends State<ReviewTab> {
  final Random _random = Random();
  Word? _currentWord;
  List<String> _choices = const [];
  _ReviewGameType _gameType = _ReviewGameType.synonymPair;
  int _round = 0;
  int _targetQuestions = 0;
  int _correctCount = 0;
  String? _feedback;
  bool _answeredCurrent = false;
  List<Word> _leftPairWords = const [];
  List<Word> _rightPairWords = const [];
  String? _selectedLeftId;
  String? _selectedRightId;
  final Set<String> _matchedPairIds = {};
  int _pairWrongAttempts = 0;
  final List<_WrongReviewItem> _wrongItems = [];
  final List<_QuestionItem> _sessionQuestions = [];
  final Map<String, Word> _reviewedWordMap = {};
  bool _showSavedDetail = false;
  bool _savingResult = false;
  String? _saveError;
  bool _submittedResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isCompleted) {
        setState(() => _showSavedDetail = false);
      } else {
        _startSession();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ReviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompleted != widget.isCompleted ||
        oldWidget.savedResult != widget.savedResult) {
      setState(() => _showSavedDetail = false);
    }
    if (!widget.isCompleted && oldWidget.words != widget.words) {
      _startSession();
    }
  }

  void _startSession() {
    if (widget.words.length < 2) {
      setState(() {
        _currentWord = null;
        _choices = const [];
        _feedback = null;
        _round = 0;
        _targetQuestions = 0;
        _correctCount = 0;
        _answeredCurrent = false;
        _wrongItems.clear();
      });
      return;
    }

    setState(() {
      _targetQuestions = 25;
      _round = 0;
      _correctCount = 0;
      _wrongItems.clear();
      _feedback = null;
      _answeredCurrent = false;
      _sessionQuestions.clear();
      _reviewedWordMap.clear();
      _saveError = null;
      _submittedResult = false;
    });
    _buildSessionQuestions();
    _nextRound();
  }

  void _buildSessionQuestions() {
    final pool = <_QuestionItem>[];
    for (final word in widget.words) {
      pool.add(_QuestionItem(word: word, type: _ReviewGameType.synonymPair));
      pool.add(_QuestionItem(word: word, type: _ReviewGameType.matchMeaning));
      pool.add(_QuestionItem(word: word, type: _ReviewGameType.fillBlank));
    }
    pool.shuffle(_random);

    final target = _targetQuestions.clamp(1, pool.length);
    _sessionQuestions
      ..clear()
      ..addAll(pool.take(target));
    _targetQuestions = _sessionQuestions.length;
  }

  void _nextRound() {
    if (_isSessionFinished) {
      _persistResult();
      return;
    }

    if (widget.words.length < 2) {
      setState(() {
        _currentWord = null;
        _choices = const [];
        _feedback = null;
        _round = 0;
      });
      return;
    }

    final questionItem = _sessionQuestions[_round];
    final word = questionItem.word;
    final gameType = questionItem.type;
    final choices = _buildChoicesForGame(word, gameType);
    final pairWords = _buildPairWords(gameType, word);

    setState(() {
      _currentWord = word;
      _gameType = gameType;
      _choices = choices;
      _leftPairWords = pairWords;
      _rightPairWords = [...pairWords]..shuffle(_random);
      _selectedLeftId = null;
      _selectedRightId = null;
      _matchedPairIds.clear();
      _pairWrongAttempts = 0;
      _feedback = null;
      _answeredCurrent = false;
      _reviewedWordMap[word.id] = word;
      _round += 1;
    });
  }

  List<String> _buildChoicesForGame(Word word, _ReviewGameType gameType) {
    if (gameType == _ReviewGameType.synonymPair) {
      return const [];
    }
    if (gameType == _ReviewGameType.fillBlank) {
      final distractors = widget.words
          .where((item) => item.id != word.id && item.hanzi.trim().isNotEmpty)
          .map((item) => item.hanzi)
          .toList()
        ..shuffle();
      return {word.hanzi, ...distractors.take(3)}.toList()..shuffle();
    }

    final distractors = widget.words
        .where((item) => item.id != word.id && item.meaning.trim().isNotEmpty)
        .map((item) => item.meaning)
        .toList()
      ..shuffle();
    return {word.meaning, ...distractors.take(3)}.toList()..shuffle();
  }

  List<Word> _buildPairWords(_ReviewGameType gameType, Word seedWord) {
    if (gameType != _ReviewGameType.synonymPair) {
      return const [];
    }
    final others = widget.words.where((word) => word.id != seedWord.id).toList()
      ..shuffle(_random);
    return [seedWord, ...others.take(3)];
  }

  String _blankSentenceFor(Word word) {
    final sentence = word.exampleHanzi.trim();
    if (sentence.isEmpty) {
      return '____ (${word.pinyin})';
    }
    if (sentence.contains(word.hanzi)) {
      return sentence.replaceFirst(word.hanzi, '____');
    }
    return '$sentence  ____';
  }

  String _questionPinyinFor(Word word) {
    final sentencePinyin = word.examplePinyin.trim();
    if (sentencePinyin.isNotEmpty) {
      return sentencePinyin;
    }
    return word.pinyin;
  }

  void _checkAnswer(String value) {
    if (_currentWord == null || _answeredCurrent) {
      return;
    }

    final target = _gameType == _ReviewGameType.fillBlank
        ? _currentWord!.hanzi
        : _currentWord!.meaning;
    final isCorrect = value == target;
    widget.onPlayAudio(_currentWord!);
    setState(() {
      _feedback = isCorrect ? 'Chính xác!' : 'Sai rồi, đáp án: $target';
      _answeredCurrent = true;
      if (isCorrect) {
        _correctCount += 1;
      } else {
        _wrongItems.add(
          _WrongReviewItem(
            question: _questionLabel(),
            userAnswer: value,
            correctAnswer: target,
          ),
        );
      }
    });
  }

  String _questionLabel() {
    if (_currentWord == null) {
      return '';
    }
    if (_gameType == _ReviewGameType.synonymPair) {
      return 'Nối từ đồng nghĩa';
    }
    if (_gameType == _ReviewGameType.matchMeaning) {
      return 'Nối nghĩa: ${_currentWord!.hanzi}';
    }
    return 'Điền từ: ${_blankSentenceFor(_currentWord!)}';
  }

  void _onTapLeftPair(Word word) {
    if (_answeredCurrent || _matchedPairIds.contains(word.id)) {
      return;
    }
    setState(() => _selectedLeftId = word.id);
    _tryResolvePair();
  }

  void _onTapRightPair(Word word) {
    if (_answeredCurrent || _matchedPairIds.contains(word.id)) {
      return;
    }
    widget.onPlayAudio(word);
    setState(() => _selectedRightId = word.id);
    _tryResolvePair();
  }

  void _tryResolvePair() {
    if (_selectedLeftId == null || _selectedRightId == null) {
      return;
    }
    final isMatch = _selectedLeftId == _selectedRightId;
    if (isMatch) {
      setState(() {
        _matchedPairIds.add(_selectedLeftId!);
        _feedback = 'Đúng cặp này!';
        _selectedLeftId = null;
        _selectedRightId = null;
      });
      if (_matchedPairIds.length == _leftPairWords.length) {
        setState(() {
          _answeredCurrent = true;
          if (_pairWrongAttempts == 0) {
            _correctCount += 1;
            _feedback = 'Hoàn thành chính xác tất cả cặp!';
          } else {
            _feedback = 'Hoàn thành, có $_pairWrongAttempts lần ghép sai.';
            _wrongItems.add(
              _WrongReviewItem(
                question: _questionLabel(),
                userAnswer: 'Sai $_pairWrongAttempts lần',
                correctAnswer: 'Ghép đúng toàn bộ cặp',
              ),
            );
          }
        });
      }
      return;
    }

    setState(() {
      _pairWrongAttempts += 1;
      _feedback = 'Sai cặp, thử lại.';
      _selectedLeftId = null;
      _selectedRightId = null;
    });
  }

  bool get _isSessionFinished =>
      _targetQuestions > 0 && _round >= _targetQuestions && _answeredCurrent;

  Future<void> _persistResult() async {
    if (widget.isCompleted || _savingResult || _submittedResult) {
      return;
    }

    final reviewedWords = _reviewedWordMap.values
        .map(
          (word) => <String, dynamic>{
            'wordId': word.id,
            'hanzi': word.hanzi,
            'pinyin': word.pinyin,
            'meaning': word.meaning,
          },
        )
        .toList();
    final wrongItems = _wrongItems
        .map(
          (item) => <String, dynamic>{
            'question': item.question,
            'userAnswer': item.userAnswer,
            'correctAnswer': item.correctAnswer,
          },
        )
        .toList();

    setState(() {
      _savingResult = true;
      _saveError = null;
    });
    try {
      await widget.onComplete(
        totalQuestions: _targetQuestions,
        correctAnswers: _correctCount,
        wrongItems: wrongItems,
        reviewedWords: reviewedWords,
      );
      if (mounted) {
        setState(() => _submittedResult = true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saveError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _savingResult = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      final result = widget.savedResult ?? <String, dynamic>{};
      final total = result['totalQuestions'] as int? ?? 0;
      final correct = result['correctAnswers'] as int? ?? 0;
      final reviewedWords =
          (result['reviewedWords'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList();
      final wrongItems =
          (result['wrongItems'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList();

      if (!_showSavedDetail) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đã hoàn thành',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.greenText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text('Kết quả: $correct/$total câu đúng'),
                  SizedBox(height: 12.h),
                  ElevatedButton(
                    onPressed: () => setState(() => _showSavedDetail = true),
                    child: const Text('Xem lại bài ôn tập'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bài ôn tập đã hoàn thành',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text('Kết quả: $correct/$total câu đúng'),
            SizedBox(height: 12.h),
            Text(
              'Các từ đã ôn tập',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp),
            ),
            SizedBox(height: 6.h),
            Expanded(
              child: ListView(
                children: [
                  ...reviewedWords.map((item) {
                    final word = Word(
                      id: item['wordId']?.toString() ?? '',
                      hanzi: item['hanzi']?.toString() ?? '',
                      pinyin: item['pinyin']?.toString() ?? '',
                      meaning: item['meaning']?.toString() ?? '',
                      hskLevel: widget.hskLevel,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${word.hanzi} [${word.pinyin}]'),
                      subtitle: Text(word.meaning),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up_outlined),
                        onPressed: () => widget.onPlayAudio(word),
                      ),
                    );
                  }),
                  SizedBox(height: 8.h),
                  Text(
                    'Câu sai + đáp án đúng',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp),
                  ),
                  SizedBox(height: 6.h),
                  if (wrongItems.isEmpty)
                    Text(
                      'Không có câu sai.',
                      style: TextStyle(color: AppColors.greenText),
                    ),
                  ...wrongItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Câu sai ${index + 1}: ${item['question']}'),
                          Text('Bạn chọn: ${item['userAnswer']}'),
                          Text(
                            'Đáp án đúng: ${item['correctAnswer']}',
                            style: TextStyle(color: AppColors.greenText),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_currentWord == null) {
      return Center(
        child: Text(
          'Cần ít nhất 2 từ để bắt đầu ôn tập.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    if (_isSessionFinished) {
      if (!_submittedResult && !widget.isCompleted && !_savingResult) {
        _persistResult();
      }
      final wrongCount = (_targetQuestions - _correctCount).clamp(0, _targetQuestions);
      return Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoàn thành $_targetQuestions câu ôn tập',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'Đúng: $_correctCount | Sai: $wrongCount',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_savingResult) ...[
              SizedBox(height: 10.h),
              const LinearProgressIndicator(),
            ],
            if (_saveError != null) ...[
              SizedBox(height: 10.h),
              Text(
                'Lỗi lưu kết quả: $_saveError',
                style: TextStyle(color: AppColors.errorText),
              ),
            ],
            SizedBox(height: 10.h),
            if (_wrongItems.isEmpty)
              Text(
                'Tuyệt vời! Không có câu sai.',
                style: TextStyle(color: AppColors.greenText),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _wrongItems.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, index) {
                    final item = _wrongItems[index];
                    return Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.borderDefault.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Câu sai ${index + 1}: ${item.question}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text('Bạn chọn: ${item.userAnswer}'),
                          Text(
                            'Đáp án đúng: ${item.correctAnswer}',
                            style: TextStyle(color: AppColors.greenText),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    }

    final gameName = switch (_gameType) {
      _ReviewGameType.synonymPair => 'Nối từ đồng nghĩa',
      _ReviewGameType.matchMeaning => 'Nối nghĩa',
      _ReviewGameType.fillBlank => 'Điền từ',
    };

    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$gameName - Câu $_round/$_targetQuestions',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17.sp),
          ),
          SizedBox(height: 8.h),
          if (_gameType == _ReviewGameType.synonymPair) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: _leftPairWords.map((word) {
                        final selected = _selectedLeftId == word.id;
                        final matched = _matchedPairIds.contains(word.id);
                        return _PairChoiceButton(
                          label: word.meaning,
                          selected: selected,
                          matched: matched,
                          onTap: () => _onTapLeftPair(word),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      children: _rightPairWords.map((word) {
                        final selected = _selectedRightId == word.id;
                        final matched = _matchedPairIds.contains(word.id);
                        return _PairChoiceButton(
                          label: '${word.hanzi} (${word.pinyin})',
                          selected: selected,
                          matched: matched,
                          onTap: () => _onTapRightPair(word),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Column(
                children: [
                  Text(
                    _gameType == _ReviewGameType.matchMeaning
                        ? 'Chọn nghĩa đúng cho từ:'
                        : 'Điền từ còn thiếu:',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _gameType == _ReviewGameType.matchMeaning
                        ? _currentWord!.hanzi
                        : _blankSentenceFor(_currentWord!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Pinyin: ${_gameType == _ReviewGameType.fillBlank ? _questionPinyinFor(_currentWord!) : _currentWord!.pinyin}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            ..._choices.map(
              (choice) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _answeredCurrent ? null : () => _checkAnswer(choice),
                    child: Text(choice, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ],
          if (_feedback != null)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                _feedback!,
                style: TextStyle(
                  color: _feedback!.startsWith('Chính')
                      ? AppColors.greenText
                      : AppColors.errorText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _answeredCurrent ? _nextRound : null,
              child: Text(_round >= _targetQuestions ? 'Hoàn thành' : 'Câu tiếp theo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionItem {
  const _QuestionItem({required this.word, required this.type});

  final Word word;
  final _ReviewGameType type;
}

class _PairChoiceButton extends StatelessWidget {
  const _PairChoiceButton({
    required this.label,
    required this.selected,
    required this.matched,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = matched
        ? AppColors.greenText
        : selected
            ? AppColors.blueDarkText
            : AppColors.borderDefault;
    final bgColor = matched
        ? AppColors.greenText.withValues(alpha: 0.12)
        : selected
            ? AppColors.blueDarkText.withValues(alpha: 0.1)
            : AppColors.backgroundWhite;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: matched ? null : onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: bgColor,
            side: BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
