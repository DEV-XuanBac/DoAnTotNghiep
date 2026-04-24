import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanziilearnapp/app/core/constants/auth_constants.dart';

String? validateSignupEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return AuthConstants.msgEmailRequired;
  }
  if (!AuthConstants.emailRegex.hasMatch(email)) {
    return AuthConstants.msgEmailInvalid;
  }
  return null;
}

String? validateSignupPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) {
    return AuthConstants.msgPasswordRequired;
  }
  if (password.length < AuthConstants.minPasswordLength) {
    return AuthConstants.msgPasswordMinLengthSignup;
  }
  return null;
}

String? validateSignupConfirmPassword({
  required String? value,
  required String originalPassword,
}) {
  final confirmPassword = value ?? '';
  if (confirmPassword.isEmpty) {
    return AuthConstants.msgConfirmPasswordRequired;
  }
  if (confirmPassword != originalPassword) {
    return AuthConstants.msgConfirmPasswordMismatch;
  }
  return null;
}

String? validateSignupUsername(String? value) {
  final username = value?.trim() ?? '';
  if (username.isEmpty) {
    return AuthConstants.msgUsernameRequired;
  }
  if (!AuthConstants.usernameRegex.hasMatch(username)) {
    return AuthConstants.msgUsernameInvalid;
  }
  return null;
}

String mapRegisterError(FirebaseAuthException error) {
  switch (error.code) {
    case 'email-already-in-use':
      return 'Email đã được đăng ký trong hệ thống.';
    case 'invalid-email':
      return AuthConstants.msgEmailInvalid;
    case 'weak-password':
      return 'Mật khẩu quá yếu, vui lòng dùng mật khẩu mạnh hơn.';
    default:
      return error.message ?? 'Đăng ký thất bại.';
  }
}
