import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:hanziilearnapp/app/providers/auth_provider.dart';
import 'package:hanziilearnapp/app/views/authencation/signup/signup_validation.dart';

enum SignupVerificationOutcome { verified, timeout, cancelled }

class SignupController extends ChangeNotifier {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();
  final GlobalKey<FormState> formK = GlobalKey<FormState>();

  bool hidePw = true;
  bool hideConfirmPw = true;
  bool waitingVerify = false;
  int remainSecs = 0;
  bool _cancelled = false;

  void togglePw() {
    hidePw = !hidePw;
    notifyListeners();
  }

  void toggleConfirmPw() {
    hideConfirmPw = !hideConfirmPw;
    notifyListeners();
  }

  String? validateConfirmPassword(String? value) {
    return validateSignupConfirmPassword(
      value: value,
      originalPassword: passCtrl.text,
    );
  }

  Future<String?> register(AuthProvider authPrv) async {
    if (!(formK.currentState?.validate() ?? false)) {
      return null;
    }

    try {
      await authPrv.startRegisterWithEmail(
        email: emailCtrl.text,
        password: passCtrl.text,
        usernameVie: nameCtrl.text,
      );
      return null;
    } on FirebaseAuthException catch (error) {
      return mapRegisterError(error);
    } catch (_) {
      return 'Không thể đăng ký tài khoản.';
    }
  }

  void beginWait(int timeoutSecs) {
    waitingVerify = true;
    _cancelled = false;
    remainSecs = timeoutSecs;
    notifyListeners();
  }

  Future<void> cancelWait(AuthProvider authPrv) async {
    _cancelled = true;
    waitingVerify = false;
    notifyListeners();
    await authPrv.cancelPendingRegistration();
  }

  Future<SignupVerificationOutcome> waitVerify(AuthProvider authPrv) async {
    while (waitingVerify && remainSecs > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!waitingVerify) {
        break;
      }
      final verified = await authPrv.checkAndFinalizeEmailVerification();
      if (verified) {
        waitingVerify = false;
        notifyListeners();
        return SignupVerificationOutcome.verified;
      }
      remainSecs--;
      notifyListeners();
    }

    if (_cancelled) {
      return SignupVerificationOutcome.cancelled;
    }
    if (waitingVerify) {
      waitingVerify = false;
      notifyListeners();
      await authPrv.cancelPendingRegistration();
      return SignupVerificationOutcome.timeout;
    }
    return SignupVerificationOutcome.cancelled;
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }
}
