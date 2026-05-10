import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/views/authencation/login_view.dart';
import 'package:hanziilearnapp/app/views/profile/profile_view.dart';

class HomeUserInfo extends StatelessWidget {
  const HomeUserInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        if (currentUser == null) {
          return _HomeUserInfoRow(
            displayName: 'Đăng nhập',
            avatar: '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
              );
            },
          );
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future:
              FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data?.data();
            final displayName = (profile?['usename_vie'] ?? '').toString().trim();
            final avatar = (profile?['avatar'] ?? '').toString().trim();

            return _HomeUserInfoRow(
              displayName:
                  displayName.isEmpty
                      ? currentUser.email ?? 'Người dùng'
                      : displayName,
              avatar: avatar,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileDemoView()),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HomeUserInfoRow extends StatelessWidget {
  const _HomeUserInfoRow({
    required this.displayName,
    required this.avatar,
    required this.onTap,
  });

  final String displayName;
  final String avatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: _HomeAvatarImage(avatar: avatar),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20.w),
            ),
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeAvatarImage extends StatelessWidget {
  const _HomeAvatarImage({required this.avatar});

  final String avatar;

  @override
  Widget build(BuildContext context) {
    const defaultAvatarPath = 'assets/logo/friend_logo.png';
    if (avatar.isEmpty) {
      return Image.asset(
        defaultAvatarPath,
        width: 48.w,
        height: 48.h,
        fit: BoxFit.cover,
      );
    }
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return Image.network(
        avatar,
        width: 48.w,
        height: 48.h,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => Image.asset(
              defaultAvatarPath,
              width: 48.w,
              height: 48.h,
              fit: BoxFit.cover,
            ),
      );
    }
    return Image.asset(
      avatar,
      width: 48.w,
      height: 48.h,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => Image.asset(
            defaultAvatarPath,
            width: 48.w,
            height: 48.h,
            fit: BoxFit.cover,
          ),
    );
  }
}
