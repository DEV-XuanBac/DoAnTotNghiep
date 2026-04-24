import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanziilearnapp/app/core/constants/auth_constants.dart';

String? validateLoginEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return AuthConstants.msgEmailRequired;
  }
  if (!AuthConstants.emailRegex.hasMatch(email)) {
    return AuthConstants.msgEmailInvalid;
  }
  return null;
}

String? validateLoginPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return AuthConstants.msgPasswordRequired;
  }
  if (password.length < AuthConstants.minPasswordLength) {
    return AuthConstants.msgPasswordMinLength;
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
      return AuthConstants.msgEmailInvalid;
    case 'too-many-requests':
      return 'Bạn thử sai quá nhiều lần, vui lòng thử lại sau.';
    default:
      return error.message ?? 'Đăng nhập thất bại.';
  }
}
