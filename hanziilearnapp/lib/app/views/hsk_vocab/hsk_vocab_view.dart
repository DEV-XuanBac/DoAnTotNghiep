import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:provider/provider.dart';

class HskVocabView extends StatefulWidget {
  const HskVocabView({super.key, required this.hskLevel});

  final String hskLevel;

  @override
  State<HskVocabView> createState() => _HskVocabViewState();
}

class _HskVocabViewState extends State<HskVocabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadWordsByHskLevel(widget.hskLevel);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F2F7),
        appBar: AppBar(
          title: Text(widget.hskLevel),
          centerTitle: true,
          backgroundColor: const Color(0xFFF1F2F7),
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: Container(
                height: 52.h,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.blueDarkText,
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                  labelColor: AppColors.whiteText,
                  unselectedLabelColor: AppColors.primaryText,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Tu vung'),
                    Tab(text: 'Mau cau'),
                    Tab(text: 'Meo'),
                    Tab(text: 'Hoi thoai'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: TabBarView(
                children: [
                  _VocabularyTab(hskLevel: widget.hskLevel),
                  const _ComingSoonTab(title: 'Mau cau dang cap nhat'),
                  const _ComingSoonTab(title: 'Meo hoc dang cap nhat'),
                  const _ComingSoonTab(title: 'Hoi thoai dang cap nhat'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabularyTab extends StatelessWidget {
  const _VocabularyTab({required this.hskLevel});

  final String hskLevel;

  @override
  Widget build(BuildContext context) {
    return Consumer<LessonProvider>(
      builder: (context, provider, _) {
        if (provider.loading && provider.words.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.words.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tai du lieu that bai',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.errorText,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  ElevatedButton(
                    onPressed: () => provider.loadWordsByHskLevel(hskLevel),
                    child: const Text('Thu lai'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.words.isEmpty) {
          return Center(
            child: Text(
              'Chua co du lieu cho $hskLevel',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadWordsByHskLevel(hskLevel),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            itemCount: provider.words.length,
            itemBuilder: (context, index) {
              final word = provider.words[index];
              return _WordCard(word: word);
            },
          ),
        );
      },
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LessonProvider>();
    final bookmarked = context.select<LessonProvider, bool>(
      (value) => value.isBookmarked(word.id),
    );

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(26.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: word.hanzi,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: 22.sp,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' [${word.pinyin}] [${word.meaning.toUpperCase()}]',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w500,
                          fontSize: 17.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        word.ttsUrl.isEmpty
                            ? 'Khong co duong dan audio cho tu nay.'
                            : 'TTS url: ${word.ttsUrl}',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.volume_up_outlined),
              ),
              IconButton(
                onPressed: () => provider.toggleBookmark(word.id),
                icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            word.meaning,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
