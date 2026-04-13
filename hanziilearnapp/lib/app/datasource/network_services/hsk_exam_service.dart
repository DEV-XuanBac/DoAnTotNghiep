import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hanziilearnapp/app/models/hsk_exam_model.dart';

class HskExamService {
  static const String _baseExamPath = 'lib/core/database_HSK_Exam';

  Future<List<HskExam>> getExamsByLevel(String level) async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final manifestMap = jsonDecode(manifestJson) as Map<String, dynamic>;

    final examFiles = manifestMap.keys
        .where((assetPath) {
          return assetPath.startsWith('$_baseExamPath/') &&
              assetPath.endsWith('.json');
        })
        .toList()
      ..sort();

    final exams = <HskExam>[];
    for (final assetPath in examFiles) {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final exam = HskExam.fromJson(decoded, assetPath);
        if (exam.level.toUpperCase() == level.toUpperCase()) {
          exams.add(exam);
        }
      }
    }
    return exams;
  }

  Future<HskExamDetail> getExamDetail(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid exam data format');
    }
    return HskExamDetail.fromJson(decoded);
  }
}
