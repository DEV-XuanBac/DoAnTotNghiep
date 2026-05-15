import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Theo dõi thời gian online trong phiên app và đồng bộ lên Firestore.
class OnlineSessionProvider extends ChangeNotifier {
  OnlineSessionProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  bool _isActive = false;
  bool get isActive => _isActive;

  late DateTime _sessionStartedAt;
  int onlineMins = 0;
  int _lastSyncedMins = 0;
  Timer? _onlineTimer;

  void startSession() {
    if (_isActive) {
      return;
    }
    _isActive = true;
    _sessionStartedAt = DateTime.now();
    onlineMins = 0;
    _lastSyncedMins = 0;
    _onlineTimer?.cancel();
    _onlineTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _tick();
    });
    notifyListeners();
  }

  void _tick() {
    onlineMins = DateTime.now().difference(_sessionStartedAt).inMinutes;
    notifyListeners();
    unawaited(syncOnlineIfNeeded());
  }

  Future<void> stopSession({bool sync = false}) async {
    if (!_isActive) {
      return;
    }
    _onlineTimer?.cancel();
    _onlineTimer = null;
    onlineMins = DateTime.now().difference(_sessionStartedAt).inMinutes;
    _isActive = false;
    if (sync) {
      await syncOnlineIfNeeded(force: true);
    }
    notifyListeners();
  }

  Future<void> syncOnlineIfNeeded({bool force = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final delta = onlineMins - _lastSyncedMins;
    if (!force && delta < 1) {
      return;
    }
    if (delta <= 0) {
      return;
    }

    _lastSyncedMins = onlineMins;
    await _firestore.collection('users').doc(user.uid).set({
      'total_online_minutes': FieldValue.increment(delta),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
