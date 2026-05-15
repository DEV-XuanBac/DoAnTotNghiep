import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hanziilearnapp/app/providers/online_session_provider.dart';
import 'package:provider/provider.dart';

/// Khởi động theo dõi thời gian online cho toàn app (mọi màn hình).
class OnlineSessionBinder extends StatefulWidget {
  const OnlineSessionBinder({super.key, required this.child});

  final Widget child;

  @override
  State<OnlineSessionBinder> createState() => _OnlineSessionBinderState();
}

class _OnlineSessionBinderState extends State<OnlineSessionBinder>
    with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSub;

  OnlineSessionProvider get _session => context.read<OnlineSessionProvider>();

  void _afterFrame(void Function() action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      action();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _afterFrame(_session.startSession);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _afterFrame(() {
        if (user == null) {
          unawaited(_session.stopSession(sync: true));
        } else if (!_session.isActive) {
          _session.startSession();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    unawaited(_session.stopSession(sync: true));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_session.syncOnlineIfNeeded(force: true));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
