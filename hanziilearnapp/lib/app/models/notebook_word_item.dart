import 'package:flutter/foundation.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

/// Một mục trong sổ tay từ vựng của người dùng.
@immutable
class NotebookWordItem {
  const NotebookWordItem({
    required this.word,
    required this.isFavorite,
    required this.note,
  });

  final Word word;
  final bool isFavorite;
  final String note;
}
