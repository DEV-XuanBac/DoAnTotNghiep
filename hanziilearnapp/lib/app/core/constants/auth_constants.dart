class AuthConstants {
  AuthConstants._();

  static final RegExp emailRegex = RegExp(
    r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
  );
  static final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9À-ỹ\s]+$');

  static const int minPasswordLength = 8;

  static const String msgEmailRequired = 'Vui lòng nhập email.';
  static const String msgEmailInvalid = 'Email không đúng định dạng.';
  static const String msgPasswordRequired = 'Vui lòng nhập mật khẩu.';
  static const String msgPasswordMinLength = 'Mật khẩu tối thiểu 8 ký tự.';
  static const String msgPasswordMinLengthSignup =
      'Mật khẩu phải có ít nhất 8 ký tự.';
  static const String msgConfirmPasswordRequired = 'Vui lòng nhập lại mật khẩu.';
  static const String msgConfirmPasswordMismatch = 'Mật khẩu nhập lại không khớp.';
  static const String msgUsernameRequired = 'Vui lòng nhập tên người dùng.';
  static const String msgUsernameInvalid = 'Tên không được chứa ký tự đặc biệt.';
}
