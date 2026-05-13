import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/widgets.dart';
import 'package:hanziilearnapp/app/providers/auth_provider.dart';
import 'package:hanziilearnapp/app/views/authencation/login/login_validation.dart';

class LoginController extends ChangeNotifier {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final GlobalKey<FormState> formK = GlobalKey<FormState>();

  bool hidePw = true;

  String? validateEmail(String? value) => validateLoginEmail(value);
  String? validatePassword(String? value) => validateLoginPassword(value);

  void togglePw() {
    hidePw = !hidePw;
    notifyListeners();
  }

  Future<String?> submit(AuthProvider authPrv) async {
    if (!(formK.currentState?.validate() ?? false)) {
      return null;
    }

    try {
      await authPrv.signInWithEmail(
        email: emailCtrl.text,
        password: passCtrl.text,
      );
      return null;
    } on FirebaseAuthException catch (error) {
      return mapLoginError(error);
    } catch (_) {
      return 'Không thể đăng nhập, vui lòng thử lại.';
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }
}
