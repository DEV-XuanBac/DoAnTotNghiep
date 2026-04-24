import 'package:hanziilearnapp/app/providers/auth_provider.dart';
import 'package:hanziilearnapp/app/providers/dictionary_provider.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:hanziilearnapp/app/providers/post_provider.dart';
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Danh sách provider đăng ký trong [MultiProvider] (pattern hit-moments).
List<SingleChildWidget> get appProviders => [
  ChangeNotifierProvider(create: (_) => DictionaryProvider()),
  ChangeNotifierProvider(create: (_) => LessonProvider()),
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => PostProvider()),
  ChangeNotifierProvider(create: (_) => ThemeProvider()),
];
