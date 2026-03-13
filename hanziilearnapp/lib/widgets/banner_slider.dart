import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/core/constants.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  int currentIndex = 0;

  final List<String> bannerImages = [
    'assets/illusimg/banner_a.jpg',
    'assets/illusimg/banner_b.jpg',
    'assets/illusimg/banner_c.jpg',
    'assets/illusimg/banner_d.jpg',
    'assets/illusimg/banner_e.jpg',
    'assets/illusimg/banner_f.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 150.h,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
          items: bannerImages.map((imagePath) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            );
          }).toList(),
        ),

        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bannerImages.asMap().entries.map((entry) {
            bool isActive = currentIndex == entry.key;
            return Container(
              width: isActive ? 8.w : 6.w,
              height: isActive ? 8.w : 6.w,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.label
                    : AppColors.secondaryText.withOpacity(0.6),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
