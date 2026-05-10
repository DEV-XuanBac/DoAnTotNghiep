import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class HskImportService {
  HskImportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _assetPath =
      'lib/core/database_cn_pinyin_vie/HSK_Words.json';

  final FirebaseFirestore _firestore;

  Future<int> importAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;

    var imported = 0;
    var opCount = 0;
    var batch = _firestore.batch();

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final data = _mapWord(item);
      final docRef = _firestore
          .collection('dictionary')
          .doc(_buildDocumentId(data));

      batch.set(docRef, data, SetOptions(merge: true));
      imported++;
      opCount++;

      if (opCount == 450) {
        await batch.commit();
        batch = _firestore.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }

    return imported;
  }

  Map<String, dynamic> _mapWord(Map<String, dynamic> raw) {
    final hskLevel = _readString(raw['level']);
    final hanzi = _readString(raw['tu_moi']);

    return {
      'stt': _readString(raw['stt']),
      'level': hskLevel,
      'hskLevel': hskLevel,
      'hanzi': hanzi,
      'pinyin': _readString(raw['phien_am']),
      'meaning': _readString(raw['giai_thich']),
      'exampleHanzi': _readString(raw['vi_du_han']),
      'examplePinyin': _readString(raw['vi_du_pinyin']),
      'exampleMeaning': _readString(raw['vi_du_dich']),
      'topic': _readString(raw['topic']),
      'ttsUrl': _readString(raw['tts_url']),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _buildDocumentId(Map<String, dynamic> data) {
    final segments = [
      _slugify(data['hskLevel']),
      _slugify(data['stt']),
      _slugify(data['hanzi']),
    ].where((segment) => segment.isNotEmpty);

    return segments.join('_');
  }

  String _readString(Object? value) {
    return value?.toString().trim() ?? '';
  }

  String _slugify(Object? value) {
    return _readString(value)
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\u4e00-\u9fff]'), '');
  }
}
