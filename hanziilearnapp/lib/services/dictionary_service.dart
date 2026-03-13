import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanziilearnapp/models/word_model.dart';

class DictionaryService {
  final db = FirebaseFirestore.instance;
  Future<List<Word>> searchWord(String keyWord) async {
    final result = await db.collection("dictionary").where("hanzi", isGreaterThanOrEqualTo: keyWord).limit(10).get();
    return result.docs.map((doc) {
      final data = doc.data();
      return Word(id: doc.id, hanzi: data["hanzi"], pinyin: data["pinyin"], meaning: data["meaning"], hskLevel: data["hskLevel"]);
    }).toList();
  }
}