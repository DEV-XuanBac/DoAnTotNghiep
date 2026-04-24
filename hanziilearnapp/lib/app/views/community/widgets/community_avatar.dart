import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    super.key,
    required this.avatar,
    this.size = 40,
  });

  final String avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    const defaultAvatarPath = 'assets/logo/friend_logo.png';
    final avatarPath = avatar.trim();

    if (avatarPath.isEmpty) {
      return _wrap(
        Image.asset(
          defaultAvatarPath,
          width: size.w,
          height: size.w,
          fit: BoxFit.cover,
        ),
      );
    }
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return _wrap(
        Image.network(
          avatarPath,
          width: size.w,
          height: size.w,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            defaultAvatarPath,
            width: size.w,
            height: size.w,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return _wrap(
      Image.asset(
        avatarPath,
        width: size.w,
        height: size.w,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          defaultAvatarPath,
          width: size.w,
          height: size.w,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _wrap(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size),
      child: child,
    );
  }
}
