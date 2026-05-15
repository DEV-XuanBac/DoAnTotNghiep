library;
import 'package:hanziilearnapp/app/models/lookup_history_item.dart';

class MainShellArgs {
  const MainShellArgs({this.initialIndex = 0});

  /// Index của tab khởi tạo (0..3).
  final int initialIndex;
}

/// Arguments cho [AppRoutes.hskVocab].
class HskVocabArgs {
  const HskVocabArgs({required this.hskLevel});
  final String hskLevel;
}

/// Arguments cho [AppRoutes.hskExamList].
class HskExamListArgs {
  const HskExamListArgs({required this.hskLevel});

  final String hskLevel;
}

/// Arguments cho [AppRoutes.hskExamTake].
class HskExamTakeArgs {
  const HskExamTakeArgs({required this.examId, required this.level});

  final String examId;
  final String level;
}

/// Arguments cho [AppRoutes.lookupHistory].
class LookupHistoryArgs {
  const LookupHistoryArgs({required this.items});

  final List<LookupHistoryItem> items;
}
