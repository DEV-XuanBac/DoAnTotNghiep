import 'package:hanziilearnapp/app/datasource/repository/dictionary_repository.dart';
import 'package:hanziilearnapp/app/datasource/repository/exam_attempt_repository.dart';
import 'package:hanziilearnapp/app/datasource/repository/hsk_exam_repository.dart';
import 'package:hanziilearnapp/app/datasource/repository/notebook_repository.dart';
import 'package:hanziilearnapp/app/datasource/repository/post_repository.dart';
import 'package:hanziilearnapp/app/datasource/repository/review_repository.dart';
import 'package:hanziilearnapp/app/providers/auth_provider.dart';
import 'package:hanziilearnapp/app/providers/online_session_provider.dart';
import 'package:hanziilearnapp/app/providers/dictionary_provider.dart';
import 'package:hanziilearnapp/app/providers/lesson_provider.dart';
import 'package:hanziilearnapp/app/providers/notebook_provider.dart';
import 'package:hanziilearnapp/app/providers/post_provider.dart';
import 'package:hanziilearnapp/app/providers/review_provider.dart';
import 'package:hanziilearnapp/app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Danh sách provider đăng ký trong [MultiProvider].
List<SingleChildWidget> get appProviders => <SingleChildWidget>[
  Provider<IDictionaryRepository>(create: (_) => DictionaryRepository()),
  Provider<IHskExamRepository>(create: (_) => HskExamRepository()),
  Provider<INotebookRepository>(create: (_) => NotebookRepository()),
  Provider<IReviewRepository>(create: (_) => ReviewRepository()),
  Provider<IPostRepository>(create: (_) => PostRepository()),
  Provider<IExamAttemptRepository>(create: (_) => ExamAttemptRepository()),

  ChangeNotifierProvider<DictionaryProvider>(
    create: (ctx) =>
        DictionaryProvider(repository: ctx.read<IDictionaryRepository>()),
  ),
  ChangeNotifierProvider<LessonProvider>(
    create: (ctx) => LessonProvider(
      dictionaryRepository: ctx.read<IDictionaryRepository>(),
      examRepository: ctx.read<IHskExamRepository>(),
    ),
  ),
  ChangeNotifierProvider<NotebookProvider>(
    create: (ctx) =>
        NotebookProvider(repository: ctx.read<INotebookRepository>()),
  ),
  ChangeNotifierProvider<ReviewProvider>(
    create: (ctx) => ReviewProvider(repository: ctx.read<IReviewRepository>()),
  ),
  ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
  ChangeNotifierProvider<OnlineSessionProvider>(
    create: (_) => OnlineSessionProvider(),
    lazy: false,
  ),
  ChangeNotifierProvider<PostProvider>(
    create: (ctx) => PostProvider(repository: ctx.read<IPostRepository>()),
  ),
  ChangeNotifierProvider<ThemeProvider>(
    create: (_) => ThemeProvider(),
    lazy: false,
  ),
];
