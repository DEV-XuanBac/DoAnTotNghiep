/// Cấu hình API bên ngoài.
class ApiConfig {
  ApiConfig._();

  static const String geminiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String googleVisionKey = String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
    defaultValue: '',
  );

  static bool get hasGemini =>
      geminiKey.isNotEmpty && geminiKey != 'YOUR_GEMINI_API_KEY';

  static bool get hasGoogleVision =>
      googleVisionKey.isNotEmpty &&
      googleVisionKey != 'YOUR_GOOGLE_VISION_API_KEY';
}
