import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class CnViDictionaryDbService {
  static const String _assetPath =
      'lib/core/database_cn_pinyin_vie/dictionary.db';
  static const String _assetHashFileName = 'dictionary.asset.hash';

  final Map<String, String?> _meaningCache = {};
  Database? _database;

  Future<String?> lookupMeaning(String phrase) async {
    final normalizedPhrase = phrase.trim();
    if (normalizedPhrase.isEmpty) {
      return null;
    }

    if (_meaningCache.containsKey(normalizedPhrase)) {
      return _meaningCache[normalizedPhrase];
    }

    final db = await _getDatabase();
    final rows = await db.query(
      'words',
      columns: ['meaning'],
      where: 'word = ?',
      whereArgs: [normalizedPhrase],
      limit: 1,
    );

    final meaning = rows.isEmpty
        ? null
        : _normalizeMeaning(rows.first['meaning'] as String?);
    _meaningCache[normalizedPhrase] = meaning;
    return meaning;
  }

  String? _normalizeMeaning(String? meaning) {
    if (meaning == null) {
      return null;
    }

    final firstVariant = meaning.split('/').first.trim();
    if (firstVariant.isEmpty) {
      return null;
    }

    final cleaned = firstVariant
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'（[^）]*）'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) {
      return null;
    }

    final looksLikeReference =
        cleaned.toLowerCase().startsWith('xem ') ||
        cleaned.contains('[') ||
        cleaned.contains(']') ||
        cleaned.contains('|') ||
        RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF]').hasMatch(cleaned);

    return looksLikeReference ? null : cleaned;
  }

  Future<Database> _getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'dictionary.db');
    final hashPath = path.join(databasesPath, _assetHashFileName);
    final assetData = await rootBundle.load(_assetPath);
    final assetBytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );
    final assetHash = _computeHash(assetBytes);

    final dbFile = File(dbPath);
    final hashFile = File(hashPath);
    final savedHash = await hashFile.exists()
        ? await hashFile.readAsString()
        : null;

    if (!await dbFile.exists() || savedHash != assetHash) {
      await Directory(path.dirname(dbPath)).create(recursive: true);
      await dbFile.writeAsBytes(assetBytes, flush: true);
      await hashFile.writeAsString(assetHash, flush: true);
    }

    _database = await openDatabase(dbPath, readOnly: true);
    return _database!;
  }

  String _computeHash(Uint8List bytes) {
    var hash = 2166136261;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
