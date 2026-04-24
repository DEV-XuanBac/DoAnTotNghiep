import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class CnViDictionaryDbService {
  static const String _assetPath =
      'lib/core/database_cn_pinyin_vie/dictionary.db';
  static const String _assetHashFileName = 'dictionary.asset.hash';

  final Map<String, String?> _meaningCache = {};
  Database? _database;

  Future<List<Word>> searchWords({
    required String keyword,
    required bool searchByVietnamese,
    int limit = 12,
  }) async {
    final normalized = _normalizeSearchText(keyword);
    if (normalized.isEmpty) {
      return const [];
    }

    final tokens = normalized
        .split(' ')
        .where((item) => item.isNotEmpty)
        .toList();
    final effectiveLimit = _resolveSuggestionLimit(tokens.length, limit);
    final db = await _getDatabase();
    final column = searchByVietnamese ? 'meaning' : 'word';

    final mergedRows = <Map<String, Object?>>[];
    final seenIds = <String>{};

    Future<void> appendRows(
      String whereClause,
      List<Object?> whereArgs, {
      int localLimit = 12,
    }) async {
      if (mergedRows.length >= effectiveLimit) {
        return;
      }

      final rows = await db.query(
        'words',
        columns: ['id', 'word', 'pinyin', 'meaning'],
        where: whereClause,
        whereArgs: whereArgs,
        limit: localLimit,
      );

      for (final row in rows) {
        final id = (row['id'] ?? '').toString();
        if (id.isEmpty || seenIds.contains(id)) {
          continue;
        }
        seenIds.add(id);
        mergedRows.add(row);
        if (mergedRows.length >= effectiveLimit) {
          break;
        }
      }
    }

    // 1) Khớp chính xác cụm từ -> ưu tiên cao nhất.
    await appendRows('LOWER($column) = ?', [
      normalized,
    ], localLimit: effectiveLimit);

    // 2) Khớp theo tiền tố cụm từ.
    await appendRows('LOWER($column) LIKE ?', [
      '$normalized%',
    ], localLimit: effectiveLimit);

    // 3) Khớp chứa đủ toàn bộ token (nếu có từ 2 token trở lên).
    if (tokens.length >= 2) {
      final conditions = List.filled(
        tokens.length,
        'LOWER($column) LIKE ?',
      ).join(' AND ');
      final args = tokens.map((token) => '%$token%').toList();
      await appendRows(conditions, args, localLimit: effectiveLimit);
    }

    // 4) Khớp chứa cả cụm từ.
    await appendRows('LOWER($column) LIKE ?', [
      '%$normalized%',
    ], localLimit: effectiveLimit);

    // 5) Fallback cho từng token riêng lẻ (chỉ dùng khi kết quả còn quá ít).
    if (mergedRows.length < effectiveLimit) {
      for (final token in tokens) {
        await appendRows('LOWER($column) LIKE ?', [
          '%$token%',
        ], localLimit: effectiveLimit);
        if (mergedRows.length >= effectiveLimit) {
          break;
        }
      }
    }

    if (!searchByVietnamese) {
      return mergedRows.take(effectiveLimit).map(_toWord).toList();
    }

    final ranked =
        mergedRows
            .map(_toWord)
            .map(
              (word) => (
                word: word,
                score: _scoreVietnameseMatch(word, normalized, tokens),
              ),
            )
            .toList()
          ..sort((a, b) {
            final scoreCompare = b.score.compareTo(a.score);
            if (scoreCompare != 0) {
              return scoreCompare;
            }
            final hanziLengthCompare = a.word.hanzi.length.compareTo(
              b.word.hanzi.length,
            );
            if (hanziLengthCompare != 0) {
              return hanziLengthCompare;
            }
            return a.word.hanzi.compareTo(b.word.hanzi);
          });

    return ranked.take(effectiveLimit).map((item) => item.word).toList();
  }

  Future<List<Word>> getRelatedWords(Word baseWord, {int limit = 10}) async {
    final db = await _getDatabase();
    final seed = _extractMeaningSeed(baseWord.meaning);
    if (seed.isEmpty) {
      return const [];
    }

    final rows = await db.query(
      'words',
      columns: ['id', 'word', 'pinyin', 'meaning'],
      where: 'meaning LIKE ? AND word != ?',
      whereArgs: ['%$seed%', baseWord.hanzi],
      limit: limit,
    );

    return rows.map(_toWord).toList();
  }

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

  Word _toWord(Map<String, Object?> row) {
    return Word(
      id: (row['id'] ?? '').toString(),
      hanzi: (row['word'] ?? '').toString(),
      pinyin: (row['pinyin'] ?? '').toString(),
      meaning: _normalizeMeaning((row['meaning'] ?? '').toString()) ?? '',
      hskLevel: '',
    );
  }

  String _extractMeaningSeed(String meaning) {
    final cleaned = meaning.trim();
    if (cleaned.isEmpty) {
      return '';
    }

    final normalized = cleaned
        .replaceAll('/', ' ')
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final parts = normalized.split(' ');
    if (parts.isEmpty) {
      return '';
    }
    return parts.first;
  }

  String _normalizeSearchText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  int _resolveSuggestionLimit(int tokenCount, int fallbackLimit) {
    if (tokenCount <= 1) {
      return fallbackLimit;
    }
    if (tokenCount == 2) {
      return fallbackLimit > 8 ? 8 : fallbackLimit;
    }
    return fallbackLimit > 6 ? 6 : fallbackLimit;
  }

  int _scoreVietnameseMatch(
    Word word,
    String normalizedKeyword,
    List<String> tokens,
  ) {
    final meaning = _normalizeSearchText(word.meaning);
    var score = 0;

    if (meaning == normalizedKeyword) {
      score += 1200;
    }

    if (meaning.startsWith('$normalizedKeyword ') ||
        meaning.startsWith('$normalizedKeyword,') ||
        meaning.startsWith('$normalizedKeyword;') ||
        meaning.startsWith('$normalizedKeyword/')) {
      score += 900;
    } else if (meaning.startsWith(normalizedKeyword)) {
      score += 700;
    } else if (meaning.contains(' $normalizedKeyword ')) {
      score += 520;
    } else if (meaning.contains(normalizedKeyword)) {
      score += 380;
    }

    final commaParts = word.meaning
        .toLowerCase()
        .split(RegExp(r'[,/;]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final exactPartIndex = commaParts.indexOf(normalizedKeyword);
    if (exactPartIndex >= 0) {
      score += 650 - (exactPartIndex * 25);
    }

    for (final token in tokens) {
      if (meaning == token) {
        score += 280;
      } else if (meaning.startsWith('$token ') ||
          meaning.startsWith('$token,')) {
        score += 200;
      } else if (meaning.contains(' $token ') || meaning.contains(token)) {
        score += 120;
      } else {
        score -= 160;
      }
    }

    // Nghĩa ngắn thường sát nghĩa hơn cho gợi ý từ vựng cơ bản.
    score -= meaning.length;
    return score;
  }
}
