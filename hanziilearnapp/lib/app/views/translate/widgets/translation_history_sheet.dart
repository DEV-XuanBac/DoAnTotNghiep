import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/constants/color_constants.dart';

class TranslationHistorySheet extends StatelessWidget {
  const TranslationHistorySheet({
    super.key,
    required this.firestore,
    required this.userId,
  });

  final FirebaseFirestore firestore;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 560.h,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
          child: Column(
            children: [
              Container(
                width: 52.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Lịch sử dịch',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: firestore
                      .collection('translation_history')
                      .where('user_id', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      final errorText = snapshot.error?.toString() ?? '';
                      return Center(
                        child: Text(
                          errorText.contains('failed-precondition')
                              ? 'Thiếu Firestore index cho lịch sử dịch.'
                              : 'Không tải được lịch sử dịch.',
                          style: TextStyle(
                            color: AppColors.errorText,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final docs = [...(snapshot.data?.docs ?? const [])];
                    docs.sort((a, b) {
                      final aTs = a.data()['created_at'];
                      final bTs = b.data()['created_at'];
                      final aMs = aTs is Timestamp
                          ? aTs.millisecondsSinceEpoch
                          : 0;
                      final bMs = bTs is Timestamp
                          ? bTs.millisecondsSinceEpoch
                          : 0;
                      return bMs.compareTo(aMs);
                    });

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'Chưa có bản dịch nào',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final item = docs[index].data();
                        final sourceText =
                            (item['source_text'] ?? '').toString().trim();
                        final translatedText =
                            (item['translated_text'] ?? '').toString().trim();
                        final translationType = (item['translation_type'] ?? 'chữ viết')
                            .toString()
                            .trim();

                        return Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.borderDefault.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kiểu dịch: $translationType',
                                style: TextStyle(
                                  color: AppColors.blueDarkText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Văn bản gốc:',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                sourceText.isEmpty ? '-' : sourceText,
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Bản dịch:',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                translatedText.isEmpty ? '-' : translatedText,
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
