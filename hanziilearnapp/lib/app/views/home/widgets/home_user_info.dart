import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/app/core/router/app_router.dart';
import 'package:hanziilearnapp/widgets/app_network_image.dart';

class HomeUserInfo extends StatefulWidget {
  const HomeUserInfo({super.key});

  @override
  State<HomeUserInfo> createState() => _HomeUserInfoState();
}

class _HomeUserInfoState extends State<HomeUserInfo> {
  /// Cache Firestore profile `Future` theo `uid` để khi `authStateChanges`
  /// emit lại (cùng user) không re-fetch.
  Future<DocumentSnapshot<Map<String, dynamic>>>? _profileFuture;
  String? _cachedUid;

  Future<DocumentSnapshot<Map<String, dynamic>>> _profileFor(String uid) {
    if (_cachedUid == uid && _profileFuture != null) {
      return _profileFuture!;
    }
    _cachedUid = uid;
    _profileFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return _profileFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        if (currentUser == null) {
          _cachedUid = null;
          _profileFuture = null;
          return _HomeUserInfoRow(
            displayName: 'Đăng nhập',
            avatar: '',
            onTap: () => AppRouter.pushLogin(context),
          );
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _profileFor(currentUser.uid),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data?.data();
            final displayName = (profile?['usename_vie'] ?? '')
                .toString()
                .trim();
            final avatar = (profile?['avatar'] ?? '').toString().trim();

            return _HomeUserInfoRow(
              displayName: displayName.isEmpty
                  ? currentUser.email ?? 'Người dùng'
                  : displayName,
              avatar: avatar,
              onTap: () => AppRouter.pushProfile(context),
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
            child: AppNetworkImage(source: avatar, width: 48.w, height: 48.h),
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
                fontSize: 14.sp,
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
