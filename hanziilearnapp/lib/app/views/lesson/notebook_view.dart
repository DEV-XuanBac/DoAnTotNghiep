import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:provider/provider.dart';

class NotebookView extends StatefulWidget {
  const NotebookView({super.key});

  @override
  State<NotebookView> createState() => _NotebookViewState();
}

class _NotebookViewState extends State<NotebookView> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
    _tts.setSpeechRate(0.45);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadNotebookWords();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String hanzi) async {
    if (hanzi.trim().isEmpty) return;
    await _tts.speak(hanzi);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
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
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: TabBar(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  indicator: BoxDecoration(
                    color: AppColors.blueDarkText,
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  labelColor: AppColors.whiteText,
                  unselectedLabelColor: AppColors.primaryText,
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
                children: [
                  _NotebookList(
                    onlyFavorite: false,
                    onSpeak: _speak,
                  ),
                  _NotebookList(
                    onlyFavorite: true,
                    onSpeak: _speak,
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Consumer<LessonProvider>(
      builder: (context, provider, _) {
        final items = onlyFavorite
            ? provider.notebookItems.where((item) => item.isFavorite).toList()
            : provider.notebookItems;

        if (items.isEmpty) {
          return Center(
            child: Text(
              onlyFavorite ? 'Chưa có từ yêu thích.' : 'Chưa có từ đã lưu.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          itemCount: items.length,
          itemBuilder: (_, index) {
            final item = items[index];
            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.borderDefault),
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
                                  color: AppColors.primaryText,
                                ),
                              ),
                              TextSpan(
                                text: ' [${item.word.pinyin}]  ${item.word.meaning}',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
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
                            border: Border.all(color: AppColors.borderDefault),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 18.sp,
                            color: AppColors.blueDarkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context
                            .read<LessonProvider>()
                            .toggleFavoriteInNotebook(item.word.id),
                        icon: Icon(
                          Icons.favorite,
                          color: item.isFavorite
                              ? Colors.red
                              : AppColors.secondaryText.withValues(alpha: 0.7),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: item.note,
                          decoration: InputDecoration(
                            hintText: 'Thêm chú thích',
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.backgroundLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          onFieldSubmitted: (value) => context
                              .read<LessonProvider>()
                              .updateNotebookNote(item.word.id, value),
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
