/// Tên route cho `Navigator.pushNamed`.
///
/// Quy ước: dùng `kebab-case` để tránh xung đột với tên class Dart và để dễ
/// đọc trong log/deep-link nếu sau này chuyển sang `go_router`.
abstract class AppRoutes {
  AppRoutes._();

  // Entry points
  static const String splash = '/';
  static const String main = '/main';

  // Auth
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';

  // Profile / settings
  static const String profile = '/profile';

  // Vocab / Lesson
  static const String hskVocab = '/hsk-vocab';
  static const String notebook = '/notebook';
  static const String lookupHistory = '/lookup-history';

  // Exam
  static const String hskExamList = '/hsk-exam-list';
  static const String hskExamTake = '/hsk-exam-take';

  // Practice
  static const String conversation = '/conversation-practice';

  // Common
  static const String camera = '/camera';
}
