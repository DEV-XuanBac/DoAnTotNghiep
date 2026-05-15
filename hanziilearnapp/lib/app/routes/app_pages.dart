import 'package:flutter/material.dart';
import 'package:hanziilearnapp/app/core/router/route_arguments.dart';
import 'package:hanziilearnapp/app/routes/app_routes.dart';
import 'package:hanziilearnapp/app/views/authencation/login_view.dart';
import 'package:hanziilearnapp/app/views/authencation/signup_view.dart';
import 'package:hanziilearnapp/app/views/common/in_app_camera_view.dart';
import 'package:hanziilearnapp/app/views/conversation/conversation_practice_view.dart';
import 'package:hanziilearnapp/app/views/exam/hsk_exam_list_view.dart';
import 'package:hanziilearnapp/app/views/exam/hsk_exam_take_view.dart';
import 'package:hanziilearnapp/app/views/home/lookup_history_view.dart';
import 'package:hanziilearnapp/app/views/hsk_vocab/hsk_vocab_view.dart';
import 'package:hanziilearnapp/app/views/lesson/notebook_view.dart';
import 'package:hanziilearnapp/app/views/onboarding/onboarding_view.dart';
import 'package:hanziilearnapp/app/views/profile/profile_view.dart';
import 'package:hanziilearnapp/app/views/shell/bottom_nav.dart';

abstract class AppPages {
  AppPages._();

  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    AppRoutes.splash: (_) => const OnboardingView(),
    AppRoutes.main: _buildMain,
    AppRoutes.login: (_) => const LoginView(),
    AppRoutes.signup: (_) => const SigninView(),
    AppRoutes.profile: (_) => const ProfileDemoView(),
    AppRoutes.hskVocab: _buildHskVocab,
    AppRoutes.notebook: (_) => const NotebookView(),
    AppRoutes.lookupHistory: _buildLookupHistory,
    AppRoutes.hskExamList: _buildHskExamList,
    AppRoutes.hskExamTake: _buildHskExamTake,
    AppRoutes.conversation: (_) => const ConversationPracticeView(),
    AppRoutes.camera: (_) => const InAppCameraView(),
  };

  static Widget _buildMain(BuildContext context) {
    final args = _argsOf<MainShellArgs>(context);
    return BottomNav(initialIndex: args?.initialIndex ?? 0);
  }

  static Widget _buildHskVocab(BuildContext context) {
    final args = _argsOf<HskVocabArgs>(context);
    return HskVocabView(hskLevel: args?.hskLevel ?? '');
  }

  static Widget _buildLookupHistory(BuildContext context) {
    final args = _argsOf<LookupHistoryArgs>(context);
    return LookupHistoryView(items: args?.items ?? const []);
  }

  static Widget _buildHskExamList(BuildContext context) {
    final args = _argsOf<HskExamListArgs>(context);
    return HskExamListView(hskLevel: args?.hskLevel ?? '');
  }

  static Widget _buildHskExamTake(BuildContext context) {
    final args = _argsOf<HskExamTakeArgs>(context);
    return HskExamTakeView(
      examId: args?.examId ?? '',
      level: args?.level ?? '',
    );
  }

  static T? _argsOf<T extends Object>(BuildContext context) {
    final raw = ModalRoute.of(context)?.settings.arguments;
    return raw is T ? raw : null;
  }
}
