import 'package:flutter/widgets.dart';
import 'package:hanziilearnapp/models/word_model.dart';
import 'package:hanziilearnapp/repos/dictionary_repository.dart';

class DictionaryProvider extends ChangeNotifier {
  final repo = DictionaryRepository();
  List<Word> words = [];

  bool loading = false;

  searchWord(String keyWord) async {
    loading = true;
    notifyListeners();

    words = await repo.search(keyWord);

    loading = false;
    notifyListeners();
  }
}