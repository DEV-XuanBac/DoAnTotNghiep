import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/core/constants.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 45.h),
            Text(
              "Góc luyện tập",
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            SizedBox(height: 20.h),
            Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    height: 100.h,
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.cardDailyOnline,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Sổ tay từ vựng",
                          style: TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 30.w),
                        Image.asset('assets/logo/take_note_ic.png'),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20.w,),
                Column(
                  children: [
                    Row(
                      children: [
                        
                      ],
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      ),
      // Sổ tay (gồm cách card nhỏ các từ vựng được lưu từ tra từ hoạc học theo chủ đề + một dòng textfield để ghi chú lại ý của mình)
      // Học theo chủ đề (mỗi chủ đề bao gồm từ vựng (kèm theo audio, lưu vào sổ tay), mẫu câu giao tiếp, đoạn hội thoại ví dụ)
      // Bài luyện nghe, luyện đọc
      // bài kiểm tra HSK (Mục đích để ôn luyện trước các kì thi HSK ngoài đời với mẫu đề có cấu trúc chuẩn)
    );
  }
}
