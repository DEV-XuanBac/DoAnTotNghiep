import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hanziilearnapp/providers/auth_provider.dart';
import 'package:hanziilearnapp/providers/dictionary_provider.dart';
import 'package:hanziilearnapp/providers/lesson_provider.dart';
import 'package:hanziilearnapp/providers/post_provider.dart';
import 'package:hanziilearnapp/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DictionaryProvider()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],

      child: ScreenUtilInit(
        designSize: Size(360, 800),
        builder: (context, child) {
          return MaterialApp(
            title: "Chinese Learning",
            debugShowCheckedModeBanner: false,
            home: child,
          );
        },
        child: OnboardingScreen(),
      ),
    );
  }
}
