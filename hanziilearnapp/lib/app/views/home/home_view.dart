import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/datasource/local/cn_vi_dictionary_db_service.dart';
import 'package:hanziilearnapp/app/models/lookup_history_item.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:hanziilearnapp/app/views/authencation/login_view.dart';
import 'package:hanziilearnapp/app/views/conversation/conversation_practice_view.dart';
import 'package:hanziilearnapp/app/views/home/lookup_history_view.dart';
import 'package:hanziilearnapp/app/views/profile/profile_view.dart';
import 'package:hanziilearnapp/app/views/shell/bottom_nav.dart';
import 'package:hanziilearnapp/widgets/banner_slider.dart';
import 'package:hanziilearnapp/widgets/handwriting_pad_sheet.dart';
import 'package:hanziilearnapp/widgets/week_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.onRequestTabChange});

  final ValueChanged<int>? onRequestTabChange;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const _streakKey = 'home.login.streak';
  static const _loginDatesKey = 'home.login.dates';
  static const _historyKey = 'home.lookup.history';

  final TextEditingController _searchController = TextEditingController();
  final CnViDictionaryDbService _dictionaryDbService =
      CnViDictionaryDbService();
  final SpeechToText _speechToText = SpeechToText();

  bool _searchToggleVi = true;
  bool _isSearching = false;
  bool _isListening = false;
  bool _isHandwritingLoading = false;
  bool _hasSubmittedSearch = false;

  String? _searchError;
  Word? _selectedWord;
  List<Word> _suggestions = [];
  List<Word> _relatedWords = [];
  List<LookupHistoryItem> _historyItems = [];

  int _streakDays = 1;
  Set<int> _checkedWeekdayIndexes = {DateTime.now().weekday - 1};

  Timer? _debounceTimer;
  Timer? _onlineTimer;
  late DateTime _sessionStartedAt;
  int _onlineMinutes = 0;
  int _lastSyncedOnlineMinutes = 0;

  @override
  void initState() {
    super.initState();
    _sessionStartedAt = DateTime.now();
    _searchController.addListener(_onSearchChanged);
    _onlineTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _onlineMinutes = DateTime.now().difference(_sessionStartedAt).inMinutes;
      });
      _syncOnlineTimeIfNeeded();
    });
    _initializeLocalState();
  }

  @override
  void dispose() {
    unawaited(_syncOnlineTimeIfNeeded(force: true));
    _debounceTimer?.cancel();
    _onlineTimer?.cancel();
    _speechToText.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadLoginStreak(prefs);
    await _loadHistory(prefs);
  }

  Future<void> _loadLoginStreak(SharedPreferences prefs) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final storedDates = prefs.getStringList(_loginDatesKey) ?? [];

    final parsedDates =
        storedDates
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .map((date) => DateTime(date.year, date.month, date.day))
            .toList()
          ..sort();

    final hasToday = parsedDates.any((date) => date == today);
    final previousDate = parsedDates.isEmpty ? null : parsedDates.last;

    var streak = prefs.getInt(_streakKey) ?? 0;
    if (!hasToday) {
      if (previousDate == null) {
        streak = 1;
      } else {
        final diff = today.difference(previousDate).inDays;
        streak = diff == 1 ? streak + 1 : 1;
      }
      parsedDates.add(today);
    }

    final latestDates = parsedDates.length > 60
        ? parsedDates.sublist(parsedDates.length - 60)
        : parsedDates;

    final thisWeekMonday = today.subtract(Duration(days: today.weekday - 1));
    final checkedIndexes = latestDates
        .where((date) => !date.isBefore(thisWeekMonday) && !date.isAfter(today))
        .map((date) => date.weekday - 1)
        .toSet();

    await prefs.setInt(_streakKey, streak);
    await prefs.setStringList(
      _loginDatesKey,
      latestDates.map((date) => date.toIso8601String()).toList(),
    );

    if (!mounted) return;
    setState(() {
      _streakDays = streak;
      _checkedWeekdayIndexes = checkedIndexes;
    });

    await _syncLoginDateToFirestore(today);
  }

  Future<void> _syncLoginDateToFirestore(DateTime today) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final key =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'login_dates': FieldValue.arrayUnion([key]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _syncOnlineTimeIfNeeded({bool force = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    final delta = _onlineMinutes - _lastSyncedOnlineMinutes;
    if (!force && delta < 1) {
      return;
    }
    if (delta <= 0) {
      return;
    }

    _lastSyncedOnlineMinutes = _onlineMinutes;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'total_online_minutes': FieldValue.increment(delta),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _loadHistory(SharedPreferences prefs) async {
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      final items =
          decoded
              .whereType<Map>()
              .map(
                (item) =>
                    LookupHistoryItem.fromJson(item.cast<String, dynamic>()),
              )
              .toList()
            ..sort((a, b) => b.searchedAt.compareTo(a.searchedAt));

      if (!mounted) return;
      setState(() => _historyItems = items);
    } catch (_) {}
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _historyItems.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(payload));
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _suggestions = [];
        _selectedWord = null;
        _relatedWords = [];
        _searchError = null;
        _hasSubmittedSearch = false;
      });
      return;
    }

    if (_hasSubmittedSearch) {
      setState(() => _hasSubmittedSearch = false);
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: 350),
      () => _fetchSuggestions(keyword),
    );
  }

  Future<void> _fetchSuggestions(String keyword) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final words = await _dictionaryDbService.searchWords(
        keyword: keyword,
        searchByVietnamese: _searchToggleVi,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = words;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = 'Không nhận diện được mặt chữ';
      });
    }
  }

  Future<void> _onSearchPressed() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _searchError = 'Không nhận diện được mặt chữ';
        _hasSubmittedSearch = true;
      });
      return;
    }

    setState(() => _hasSubmittedSearch = true);

    if (_suggestions.isEmpty) {
      await _fetchSuggestions(keyword);
    }
    if (_suggestions.isEmpty) {
      setState(() => _searchError = 'Không nhận diện được mặt chữ');
      return;
    }

    await _selectWord(_suggestions.first, saveToHistory: true, query: keyword);
  }

  Future<void> _selectWord(
    Word word, {
    required bool saveToHistory,
    required String query,
  }) async {
    setState(() {
      _selectedWord = word;
      _searchError = null;
    });

    final related = await _dictionaryDbService.getRelatedWords(word);
    if (!mounted) return;
    setState(() => _relatedWords = related);

    if (!saveToHistory) {
      return;
    }

    final item = LookupHistoryItem(
      word: word,
      searchedAt: DateTime.now(),
      searchMode: _searchToggleVi ? 'vietnamese' : 'hanzi',
      query: query,
    );

    _historyItems.removeWhere((history) => history.word.id == item.word.id);
    _historyItems.insert(0, item);
    if (_historyItems.length > 100) {
      _historyItems = _historyItems.sublist(0, 100);
    }
    await _persistHistory();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _isListening = status == 'listening');
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _searchError = 'Không nhận diện được mặt chữ';
        });
      },
    );

    if (!available) {
      setState(() => _searchError = 'Không nhận diện được mặt chữ');
      return;
    }

    final locales = await _speechToText.locales();
    final locale = _searchToggleVi
        ? _firstWhereOrNull(locales, (item) => item.localeId.startsWith('vi'))
        : _firstWhereOrNull(locales, (item) => item.localeId.startsWith('zh'));

    await _speechToText.listen(
      localeId: locale?.localeId,
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty) {
          return;
        }
        _searchController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
    );
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) predicate) {
    for (final item in items) {
      if (predicate(item)) {
        return item;
      }
    }
    return null;
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

    setState(() {
      _isHandwritingLoading = true;
      _searchError = null;
    });

    final recognizer = TextRecognizer(
      script: _searchToggleVi
          ? TextRecognitionScript.latin
          : TextRecognitionScript.chinese,
    );
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(submission.imagePath),
      );
      final text = result.text.trim();
      if (text.isEmpty) {
        throw const FormatException('Không nhận diện được mặt chữ');
      }
      _searchController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } catch (_) {
      setState(() => _searchError = 'Không nhận diện được mặt chữ');
    } finally {
      recognizer.close();
      if (mounted) {
        setState(() => _isHandwritingLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>().isDarkMode;
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

                Positioned(top: 175.h, left: 10.w, child: _buildUserInfo()),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchCard(),
                  if (_searchError != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      _searchError!,
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
                  _buildUtilitiesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        if (currentUser == null) {
          return _buildUserInfoRow(
            displayName: 'Đăng nhập',
            avatar: '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
            },
          );
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get(),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data?.data();
            final displayName = (profile?['usename_vie'] ?? '')
                .toString()
                .trim();
            final avatar = (profile?['avatar'] ?? '').toString().trim();

            return _buildUserInfoRow(
              displayName: displayName.isEmpty
                  ? currentUser.email ?? 'Người dùng'
                  : displayName,
              avatar: avatar,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileDemoView()),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserInfoRow({
    required String displayName,
    required String avatar,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: _buildAvatarImage(avatar),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.lightCardBackground.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20.w),
            ),
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(String avatar) {
    const defaultAvatarPath = 'assets/logo/friend_logo.png';
    if (avatar.isEmpty) {
      return Image.asset(
        defaultAvatarPath,
        width: 48.w,
        height: 48.h,
        fit: BoxFit.cover,
      );
    }
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return Image.network(
        avatar,
        width: 48.w,
        height: 48.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          defaultAvatarPath,
          width: 48.w,
          height: 48.h,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      avatar,
      width: 48.w,
      height: 48.h,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        defaultAvatarPath,
        width: 48.w,
        height: 48.h,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.borderDefault.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _onSearchPressed,
                icon: Icon(
                  Icons.search,
                  color: AppColors.secondaryText,
                  size: 30.w,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _onSearchPressed(),
                  decoration: InputDecoration(
                    hintText: _searchToggleVi
                        ? 'Nhập tiếng Việt'
                        : 'Nhập tiếng Hán',
                    hintStyle: TextStyle(
                      color: AppColors.secondaryText.withValues(alpha: 0.8),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: AppColors.toggleBackgrouund,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleChip('CN', !_searchToggleVi),
                    _buildToggleChip('VI', _searchToggleVi),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'assets/iconic/microphone_ic.png',
                onTap: _toggleListening,
                isActive: _isListening,
              ),
              _buildActionButton(
                'assets/iconic/pen_ic.png',
                onTap: _openHandwritingPad,
                isActive: _isHandwritingLoading,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionPanel() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasSubmittedSearch) {
      return const SizedBox.shrink();
    }
    if (_searchController.text.trim().isEmpty || _suggestions.isEmpty) {
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
          ..._suggestions.take(6).map((word) {
            return InkWell(
              onTap: () => _selectWord(
                word,
                saveToHistory: false,
                query: _searchController.text.trim(),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: _WordTile(word: word),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    if (_selectedWord == null) {
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
          _WordTile(word: _selectedWord!),
          if (_relatedWords.isNotEmpty) ...[
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
            ..._relatedWords.take(8).map((word) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: _WordTile(word: word),
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
                                'Đã online được $_onlineMinutes phút',
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
                        '$_streakDays',
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
                child: WeekProgress(checkedDayIndexes: _checkedWeekdayIndexes),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUtilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'Tiện ích',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConversationPracticeView(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.talkButton.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/logo/panda_talking_ic.png',
                      width: 70.w,
                      height: 70.h,
                    ),
                    Text(
                      'Luyện nói',
                      style: TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                // Lịch sử tìm kiếm
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LookupHistoryView(items: _historyItems),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.historyButton,
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Lịch sử',
                          style: TextStyle(
                            color: AppColors.blueDarkText,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 20.w),
                        Image.asset(
                          'assets/iconic/history_search_ic.png',
                          width: 36.w,
                          height: 36.h,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                // Từ vựng HSK
                GestureDetector(
                  onTap: () {
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
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 17.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.vocabularyButton,
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Từ vựng',
                          style: TextStyle(
                            color: AppColors.vocabDarkText,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Image.asset(
                          'assets/logo/dict_hsk_ic.png',
                          width: 36.w,
                          height: 36.h,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildToggleChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () async {
        if (_isListening) {
          await _speechToText.stop();
        }
        setState(() {
          _searchToggleVi = label == 'VI';
          _searchError = null;
          _selectedWord = null;
          _relatedWords = [];
          _suggestions = [];
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.toggleSelected
              : AppColors.toggleBackgrouund,
          borderRadius: BorderRadius.circular(14.w),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String img, {
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.blueDarkText.withValues(alpha: 0.85)
              : AppColors.cardItem.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14.w),
        ),
        child: Image.asset(
          img,
          width: 20.w,
          height: 20.h,
          color: isActive
              ? AppColors.whiteText
              : AppColors.lightBlackText.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            word.hanzi,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            word.pinyin,
            style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryText),
          ),
          SizedBox(height: 2.h),
          Text(
            word.meaning,
            style: TextStyle(fontSize: 14.sp, color: AppColors.primaryText),
          ),
        ],
      ),
    );
  }
}
