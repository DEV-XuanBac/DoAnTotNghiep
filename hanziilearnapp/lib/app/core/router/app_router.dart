import 'package:flutter/material.dart';
import 'package:hanziilearnapp/app/core/router/route_arguments.dart';
import 'package:hanziilearnapp/app/models/lookup_history_item.dart';
import 'package:hanziilearnapp/app/routes/app_routes.dart';
import 'package:hanziilearnapp/app/views/exam/hsk_exam_take_view.dart';

abstract class AppRouter {
  AppRouter._();

  // ----- Auth -----

  static Future<void> pushLogin(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.login);
  }

  static Future<void> pushSignup(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.signup);
  }

  // ----- Profile -----

  static Future<void> pushProfile(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.profile);
  }

  // ----- Vocab / Lesson -----

  static Future<void> pushHskVocab(
    BuildContext context, {
    required String hskLevel,
  }) {
    return Navigator.of(context).pushNamed(
      AppRoutes.hskVocab,
      arguments: HskVocabArgs(hskLevel: hskLevel),
    );
  }

  static Future<void> pushNotebook(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.notebook);
  }

  static Future<void> pushLookupHistory(
    BuildContext context, {
    required List<LookupHistoryItem> items,
  }) {
    return Navigator.of(context).pushNamed(
      AppRoutes.lookupHistory,
      arguments: LookupHistoryArgs(items: items),
    );
  }

  // ----- Exam -----

  static Future<void> pushHskExamList(
    BuildContext context, {
    required String hskLevel,
  }) {
    return Navigator.of(context).pushNamed(
      AppRoutes.hskExamList,
      arguments: HskExamListArgs(hskLevel: hskLevel),
    );
  }

  /// Trả về `true` nếu user hoàn thành đề; `null` khi back ra giữa chừng.
  static Future<bool?> pushHskExamTake(
    BuildContext context, {
    required String examId,
    required String level,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HskExamTakeView(examId: examId, level: level),
      ),
    );
  }

  // ----- Practice -----

  static Future<void> pushConversationPractice(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.conversation);
  }

  // ----- Common -----

  /// Mở camera in-app; trả về đường dẫn ảnh đã chụp (`null` nếu user huỷ).
  static Future<String?> pushCamera(BuildContext context) {
    return Navigator.of(context).pushNamed<String>(AppRoutes.camera);
  }

  // ----- Shell -----

  /// Mở [BottomNav] với tab được chọn, thay thế toàn bộ stack hiện tại.
  static Future<void> goToMainTab(
    BuildContext context, {
    int initialIndex = 0,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.main,
      (route) => false,
      arguments: MainShellArgs(initialIndex: initialIndex),
    );
  }

  /// Variant `pushReplacement` (không clear stack).
  static Future<void> replaceWithMainTab(
    BuildContext context, {
    int initialIndex = 0,
  }) {
    return Navigator.of(context).pushReplacementNamed(
      AppRoutes.main,
      arguments: MainShellArgs(initialIndex: initialIndex),
    );
  }
}
