import 'package:flutter/widgets.dart';
import 'package:hanziilearnapp/app/datasource/network_services/dictionary_service.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';

class DictionaryProvider extends ChangeNotifier {
  final _service = DictionaryService();

  List<Word> words = [];
  bool loading = false;

  Future<void> searchWord(String keyWord) async {
    loading = true;
    notifyListeners();

    words = await _service.searchWord(keyWord);

    loading = false;
    notifyListeners();
  }
}
