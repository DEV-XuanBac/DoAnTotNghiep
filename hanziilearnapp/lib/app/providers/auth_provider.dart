import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  bool _registering = false;
  bool get registering => _registering;
  bool _signingIn = false;
  bool get signingIn => _signingIn;

  Future<void> startRegisterWithEmail({
    required String email,
    required String password,
    required String usernameVie,
  }) async {
    _registering = true;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedUsernameVie = usernameVie.trim();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final userId = credential.user?.uid;
      if (userId == null || userId.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-user-id',
          message: 'Không tạo được tài khoản người dùng.',
        );
      }

      await _firestore.collection('users').doc(userId).set({
        'user_id': userId,
        'email': normalizedEmail,
        'usename_vie': normalizedUsernameVie,
        'usename_cn': '',
        'avatar': '',
        'email_verified': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await credential.user?.sendEmailVerification();
    } finally {
      _registering = false;
      notifyListeners();
    }
  }

  Future<bool> checkAndFinalizeEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      return false;
    }

    await _firestore.collection('users').doc(refreshedUser.uid).set({
      'user_id': refreshedUser.uid,
      'email': (refreshedUser.email ?? '').trim().toLowerCase(),
      'email_verified': true,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  Future<void> cancelPendingRegistration() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final userId = user.uid;

    await _firestore
        .collection('users')
        .doc(userId)
        .delete()
        .catchError((_) {});
    await user.delete().catchError((_) {});
    await _auth.signOut();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _signingIn = true;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final userId = credential.user?.uid;
      if (userId == null || userId.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-user-id',
          message: 'Không lấy được thông tin tài khoản.',
        );
      }

      await credential.user?.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await refreshedUser?.sendEmailVerification();
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Tài khoản chưa xác thực email.',
        );
      }

      await _firestore.collection('users').doc(userId).set({
        'user_id': userId,
        'email': normalizedEmail,
        'email_verified': true,
        'login_dates': FieldValue.arrayUnion([_todayKey()]),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _todayKey() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
