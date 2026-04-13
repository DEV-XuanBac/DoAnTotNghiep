/// Cấu hình API bên ngoài.
///
/// **Đọc key lúc build** qua `--dart-define` hoặc file JSON (xem [dart_defines.example.json]).
///
/// Lưu ý bảo mật: key nhúng trong APK/IPA **không thể giấu tuyệt đối** — người ta vẫn có thể
/// trích từ bản cài. Cách an toàn cho production: **proxy qua backend** (Cloud Functions /
/// API riêng), key chỉ đặt trên server.
///
/// Gợi ý triển khai:
/// - Dev / nội bộ: `dart_defines.json` (đã thêm vào `.gitignore`) + lệnh bên dưới.
/// - CI (GitHub Actions…): inject secret thành `dart_defines.json` hoặc biến môi trường rồi build.
/// - Store: dùng cùng cơ chế CI, **không** commit file chứa key.
///
/// ```
/// copy dart_defines.example.json dart_defines.json
/// # sửa GEMINI_API_KEY trong dart_defines.json
/// flutter run --dart-define-from-file=dart_defines.json
/// flutter build apk --dart-define-from-file=dart_defines.json
/// ```
class ApiConfig {
  ApiConfig._();

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_GEMINI_API_KEY';
}
