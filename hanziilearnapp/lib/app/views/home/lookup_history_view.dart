import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/theme/app_palette.dart';
import 'package:hanziilearnapp/app/models/lookup_history_item.dart';

class LookupHistoryView extends StatefulWidget {
  const LookupHistoryView({super.key, required this.items});

  final List<LookupHistoryItem> items;

  @override
  State<LookupHistoryView> createState() => _LookupHistoryViewState();
}

class _LookupHistoryViewState extends State<LookupHistoryView> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      if (_keyword.isEmpty) {
        return true;
      }
      final query = _keyword.toLowerCase();
      return item.word.hanzi.toLowerCase().contains(query) ||
          item.word.meaning.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: context.palette.backgroundLight,
      appBar: AppBar(
        backgroundColor: context.palette.backgroundLight,
        elevation: 0,
        title: const Text('Lịch sử tra cứu'),
      ),
      body: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _keyword = value.trim()),
              decoration: InputDecoration(
                hintText: 'Tìm theo Hán tự hoặc tiếng Việt',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.palette.backgroundWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có lịch sử tra cứu',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.palette.secondaryText,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        return Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: context.palette.backgroundWhite,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: context.palette.borderDefault.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.word.hanzi,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: context.palette.primaryText,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                item.word.pinyin,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: context.palette.secondaryText,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                item.word.meaning,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: context.palette.primaryText,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '${_formatDateTime(item.searchedAt)} • ${item.searchMode == 'hanzi' ? 'Tìm theo Hán tự' : 'Tìm theo tiếng Việt'}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: context.palette.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final date = value.toLocal();
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }
}
