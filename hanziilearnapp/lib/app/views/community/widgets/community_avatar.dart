import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/widgets/app_network_image.dart';

class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({super.key, required this.avatar, this.size = 40});

  final String avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sz = size.w;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size),
      child: AppNetworkImage(
        source: avatar.trim(),
        width: sz,
        height: sz,
      ),
    );
  }
}
