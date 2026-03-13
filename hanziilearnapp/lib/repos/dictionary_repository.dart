import 'package:hanziilearnapp/models/word_model.dart';
import 'package:hanziilearnapp/services/dictionary_service.dart';

class DictionaryRepository {
  final service = DictionaryService();

  Future<List<Word>> search(String keyWord) {
    return service.searchWord(keyWord);
  }
}