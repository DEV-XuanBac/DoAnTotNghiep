import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanziilearnapp/app/core/constants/auth_constants.dart';

String? validateLoginEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return AuthConstants.errEmailRequired;
  }
  if (!AuthConstants.emailRx.hasMatch(email)) {
    return AuthConstants.errEmailInvalid;
  }
  return null;
}

String? validateLoginPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return AuthConstants.errPwRequired;
  }
  if (password.length < AuthConstants.minPwLen) {
    return AuthConstants.errPwMinLen;
  }
  return null;
}

String mapLoginError(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-not-verified':
      return 'Tài khoản chưa xác thực email. Vui lòng kiểm tra hộp thư.';
    case 'user-not-found':
      return 'Email chưa được đăng ký.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email hoặc mật khẩu không chính xác.';
    case 'invalid-email':
      return AuthConstants.errEmailInvalid;
    case 'too-many-requests':
      return 'Bạn thử sai quá nhiều lần, vui lòng thử lại sau.';
    default:
      return error.message ?? 'Đăng nhập thất bại.';
  }
}
