import 'package:flutter/widgets.dart';
import 'package:hanziilearnapp/app/datasource/repository/dictionary_repository.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

class DictionaryProvider extends ChangeNotifier {
  DictionaryProvider({IDictionaryRepository? repository})
    : _repo = repository ?? DictionaryRepository();

  final IDictionaryRepository _repo;

  List<Word> words = [];
  bool loading = false;

  Future<void> searchWord(String keyWord) async {
    loading = true;
    notifyListeners();

    words = await _repo.searchWord(keyWord);

    loading = false;
    notifyListeners();
  }
}
