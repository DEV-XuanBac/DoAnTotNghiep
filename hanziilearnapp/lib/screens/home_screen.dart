import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/core/constants.dart';
import 'package:hanziilearnapp/widgets/gift_animation.dart';
import 'package:hanziilearnapp/widgets/banner_slider.dart';
import 'package:hanziilearnapp/widgets/week_progress.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _searchToggleVi = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                ClipRRect(
                  child: Image.asset(
                    'assets/logo/bg_home.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220.h,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 110.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: BannerSlider(),
                    ),

                    SizedBox(height: 16.h),

                    // Personal Section
                    Padding(
                      padding: EdgeInsets.only(left: 14.w),
                      child: Text(
                        "Cá nhân",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: AppColors.cardPersonal.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20.w),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(50.r),
                                    child: Image.asset(
                                      'assets/logo/friend_logo.png',
                                      width: 80.w,
                                      height: 80.h,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0.w,
                                    bottom: 50.h,
                                    child: Container(
                                      width: 24.w,
                                      height: 24.h,
                                      decoration: BoxDecoration(
                                        color: AppColors.whiteCard.withOpacity(
                                          0.7,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "1",
                                          style: TextStyle(
                                            color: AppColors.blueDarkText,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 6.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mỗi ngày một từ vựng mới',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText.withOpacity(
                                        0.8,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Đã online 5 phút',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 22.w),
                              GiftAnimation(),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: WeekProgress(),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.only(left: 14.w),
                      child: Text(
                        "Tiện ích",
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
                        // Luyện nói với AI
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 40.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.talkButton.withOpacity(0.8),
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
                            // Danh sách từ đã tra cứu
                            GestureDetector(
                              onTap: () {},
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
                            // Danh sách từ vựng HSK
                            GestureDetector(
                              onTap: () {},
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
                    SizedBox(height: 20.h),
                  ],
                ),
              ],
            ),

            // User Info
            Positioned(
              left: 16.w,
              top: 150.h,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      'assets/logo/logo.png',
                      width: 48.w,
                      height: 48.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10.w),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightCardBackground.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20.w),
                    ),
                    child: Text(
                      'Xuân Bắc',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Positioned(
              top: 210.h,
              left: 2.w,
              right: 2.w,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 106.h,
                decoration: BoxDecoration(
                  color: AppColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(20.w),
                  border: Border.all(
                    color: AppColors.secondaryText.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Image.asset(
                            'assets/iconic/search_ic.png',
                            width: 22.w,
                            height: 22.h,
                            color: AppColors.secondaryText.withOpacity(0.8),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Nhập tiếng Việt',
                              hintStyle: TextStyle(
                                color: AppColors.secondaryText.withOpacity(0.8),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 14.h,
                              ),
                            ),
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 16.w),
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
                        // Tìm từ vựng theo giọng nói
                        _buildActionButton('assets/iconic/microphone_ic.png'),
                        // Tìm kiếm theo nhận dạng chữ viết
                        _buildActionButton('assets/iconic/pen_ic.png'),
                        // Tìm kiếm theo bộ thủ
                        _buildActionButton('assets/iconic/piece_ic.png'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _searchToggleVi = label == 'VI'),
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

  Widget _buildActionButton(String img) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.cardItem.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14.w),
        ),
        child: Image.asset(
          img,
          width: 20.w,
          height: 20.h,
          color: AppColors.lightBlackText.withOpacity(0.8),
        ),
      ),
    );
  }
}
