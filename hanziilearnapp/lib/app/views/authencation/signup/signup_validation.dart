import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanziilearnapp/app/core/constants/auth_constants.dart';

String? validateSignupEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return AuthConstants.errEmailRequired;
  }
  if (!AuthConstants.emailRx.hasMatch(email)) {
    return AuthConstants.errEmailInvalid;
  }
  return null;
}

String? validateSignupPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return AuthConstants.errPwRequired;
  }
  if (password.length < AuthConstants.minPwLen) {
    return AuthConstants.errPwMinLenSignup;
  }
  return null;
}

String? validateSignupConfirmPassword({
  required String? value,
  required String originalPassword,
}) {
  final confirmPassword = value ?? '';
  if (confirmPassword.isEmpty) {
    return AuthConstants.errConfirmPwRequired;
  }
  if (confirmPassword != originalPassword) {
    return AuthConstants.errConfirmPwMismatch;
  }
  return null;
}

String? validateSignupUsername(String? value) {
  final username = value?.trim() ?? '';
  if (username.isEmpty) {
    return AuthConstants.errUserRequired;
  }
  if (!AuthConstants.userRx.hasMatch(username)) {
    return AuthConstants.errUserInvalid;
  }
  return null;
}

String mapRegisterError(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return 'Email đã được đăng ký trong hệ thống.';
    case 'invalid-email':
      return AuthConstants.errEmailInvalid;
    case 'weak-password':
      return 'Mật khẩu quá yếu, vui lòng dùng mật khẩu mạnh hơn.';
    default:
      return error.message ?? 'Đăng ký thất bại.';
  }
}
