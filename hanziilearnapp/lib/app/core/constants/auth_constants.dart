class AuthConstants {
  AuthConstants._();

  static final RegExp emailRx = RegExp(
    r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
  );
  static final RegExp userRx = RegExp(r'^[a-zA-Z0-9À-ỹ\s]+$');

  static const int minPwLen = 8;

  static const String errEmailRequired = 'Vui lòng nhập email.';
  static const String errEmailInvalid = 'Email không đúng định dạng.';
  static const String errPwRequired = 'Vui lòng nhập mật khẩu.';
  static const String errPwMinLen = 'Mật khẩu tối thiểu 8 ký tự.';
  static const String errPwMinLenSignup =
      'Mật khẩu phải có ít nhất 8 ký tự.';
  static const String errConfirmPwRequired = 'Vui lòng nhập lại mật khẩu.';
  static const String errConfirmPwMismatch = 'Mật khẩu nhập lại không khớp.';
  static const String errUserRequired = 'Vui lòng nhập tên người dùng.';
  static const String errUserInvalid = 'Tên không được chứa ký tự đặc biệt.';
}
