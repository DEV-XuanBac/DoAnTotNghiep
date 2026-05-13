import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/providers/notebook_provider.dart';
import 'package:provider/provider.dart';

class NotebookView extends StatefulWidget {
  const NotebookView({super.key});

  @override
  State<NotebookView> createState() => _NotebookViewState();
}

class _NotebookViewState extends State<NotebookView>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late final TabController _tabController;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    unawaited(_tts.setLanguage('zh-CN'));
    unawaited(_tts.setSpeechRate(0.45));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(context.read<NotebookProvider>().loadNotebookWords());
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index != _lastTabIndex) {
      _lastTabIndex = _tabController.index;
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _speak(String hanzi) async {
    if (hanzi.trim().isEmpty) return;
    await _tts.speak(hanzi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        backgroundColor: context.palette.backgroundLight,
        elevation: 0,
        title: const Text('Sổ tay học tập'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: context.palette.backgroundWhite,
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: TabBar(
                controller: _tabController,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                indicator: BoxDecoration(
                  color: context.palette.blueDarkText,
                  borderRadius: BorderRadius.circular(22.r),
                ),
                labelColor: context.palette.whiteText,
                unselectedLabelColor: context.palette.primaryText,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Đã lưu'),
                  Tab(text: 'Yêu thích'),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _NotebookList(onlyFavorite: false, onSpeak: _speak),
                _NotebookList(onlyFavorite: true, onSpeak: _speak),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookList extends StatelessWidget {
  const _NotebookList({required this.onlyFavorite, required this.onSpeak});

  final bool onlyFavorite;
  final Future<void> Function(String hanzi) onSpeak;

  @override
  Widget build(BuildContext context) {
    return Consumer<NotebookProvider>(
      builder: (context, provider, _) {
        final items = onlyFavorite
            ? provider.notebookItems.where((item) => item.isFavorite).toList()
            : provider.notebookItems;

        if (items.isEmpty) {
          return Center(
            child: Text(
              onlyFavorite ? 'Chưa có từ yêu thích.' : 'Chưa có từ đã lưu.',
              style: TextStyle(color: context.palette.secondaryText),
            ),
          );
        }

        return ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.palette.backgroundWhite,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: context.palette.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: item.word.hanzi,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18.sp,
                                  color: context.palette.primaryText,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' [${item.word.pinyin}]  ${item.word.meaning}',
                                style: TextStyle(
                                  color: context.palette.secondaryText,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => onSpeak(item.word.hanzi),
                        child: Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            border: Border.all(color: context.palette.borderDefault),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 18.sp,
                            color: context.palette.blueDarkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => unawaited(
                          context
                              .read<NotebookProvider>()
                              .toggleFavoriteInNotebook(item.word.id),
                        ),
                        icon: Icon(
                          Icons.favorite,
                          color: item.isFavorite
                              ? Colors.red
                              : context.palette.secondaryText.withValues(alpha: 0.7),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: item.note,
                          cursorColor: context.palette.blueDarkText,
                          cursorHeight: 18.h,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            letterSpacing: 0.15,
                            color: context.palette.primaryText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Thêm chú thích',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            filled: true,
                            fillColor: context.palette.toolButton.withValues(
                              alpha: 0.12,
                            ),
                            hintStyle: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                              color: context.palette.secondaryText.withValues(
                                alpha: 0.85,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: context.palette.toolButton.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: context.palette.toolButton.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                          ),
                          onFieldSubmitted: (value) => unawaited(
                            context
                                .read<NotebookProvider>()
                                .updateNotebookNote(item.word.id, value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
