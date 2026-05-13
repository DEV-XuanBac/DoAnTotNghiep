import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hanziilearnapp/app/models/word_model.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class CnViDictionaryDbService {
  static const String _assetPath =
      'lib/core/database_cn_pinyin_vie/dictionary.db';
  static const String _assetHashFile = 'dictionary.asset.hash';

  final Map<String, String?> _meaningMap = {};
  Database? _db;

  Future<List<Word>> searchWords({
    required String keyword,
    required bool searchByVietnamese,
    int limit = 12,
  }) async {
    final normalized = _normalizeSearchText(keyword);
    if (normalized.isEmpty) {
      return const [];
    }

    final tokens = _tokenize(
      normalized,
    ); // Tách thành token để tìm kiếm linh hoạt hơn
    final effectiveLimit = _resolveSuggestionLimit(
      tokens.length,
      limit,
    ); // Điều chỉnh limit dựa trên số lượng token
    final db = await _getDatabase();
    final column = searchByVietnamese ? 'meaning' : 'word';

    final mergedRows = await _collectSearchRows(
      db: db,
      column: column,
      normalized: normalized,
      tokens: tokens,
      effectiveLimit: effectiveLimit,
    ); // sắp xếp theo độ ưu tiên (tìm kiếm theo tiếng Việt)

    if (!searchByVietnamese) {
      return mergedRows.take(effectiveLimit).map(_toWord).toList();
    } // Tìm kiếm theo tiếng Hán thì sẽ bỏ qua bước đánh giá độ ưu tiên

    return _rankVietnameseResults(
      rows: mergedRows,
      normalizedKeyword: normalized,
      tokens: tokens,
      limit: effectiveLimit,
    ); // Kết quả trả về khi tìm kiếm theo tiếng Việt
  }

  // Thu thập kết quả tìm kiếm theo thứ tự ưu tiên
  Future<List<Map<String, Object?>>> _collectSearchRows({
    required Database db,
    required String column,
    required String normalized,
    required List<String> tokens,
    required int effectiveLimit,
  }) async {
    final mergedRows = <Map<String, Object?>>[];
    final seenIds = <String>{};

    // 1) Khớp chính xác cụm từ -> ưu tiên cao nhất.
    await _appendRows(
      db: db,
      targetRows: mergedRows,
      seenIds: seenIds,
      effectiveLimit: effectiveLimit,
      whereClause: 'LOWER($column) = ?',
      whereArgs: [normalized],
    );

    // 2) Khớp theo tiền tố cụm từ.
    await _appendRows(
      db: db,
      targetRows: mergedRows,
      seenIds: seenIds,
      effectiveLimit: effectiveLimit,
      whereClause: 'LOWER($column) LIKE ?',
      whereArgs: ['$normalized%'],
    );

    // 3) Khớp chứa đủ toàn bộ token (nếu có từ 2 token trở lên).
    if (tokens.length >= 2) {
      final conditions = List.filled(
        tokens.length,
        'LOWER($column) LIKE ?',
      ).join(' AND ');
      final args = tokens.map((token) => '%$token%').toList();
      await _appendRows(
        db: db,
        targetRows: mergedRows,
        seenIds: seenIds,
        effectiveLimit: effectiveLimit,
        whereClause: conditions,
        whereArgs: args,
      );
    }

    // 4) Khớp chứa cả cụm từ.
    await _appendRows(
      db: db,
      targetRows: mergedRows,
      seenIds: seenIds,
      effectiveLimit: effectiveLimit,
      whereClause: 'LOWER($column) LIKE ?',
      whereArgs: ['%$normalized%'],
    );

    return mergedRows;
  }

  // Thêm các hàng kết quả vào danh sách mergedRows
  Future<void> _appendRows({
    required Database db,
    required List<Map<String, Object?>> targetRows,
    required Set<String> seenIds,
    required int effectiveLimit,
    required String whereClause,
    required List<Object?> whereArgs,
  }) async {
    if (targetRows.length >= effectiveLimit) {
      return;
    }

    final rows = await db.query(
      'words',
      columns: ['id', 'word', 'pinyin', 'meaning'],
      where: whereClause,
      whereArgs: whereArgs,
      limit: effectiveLimit,
    );

    for (final row in rows) {
      final id = (row['id'] ?? '').toString();
      if (id.isEmpty || seenIds.contains(id)) {
        continue;
      }
      seenIds.add(id);
      targetRows.add(row);
      if (targetRows.length >= effectiveLimit) {
        break;
      }
    }
  }

  // Sắp xếp kết quả tìm kiếm tiếng Việt dựa trên mức độ khớp và vị trí của từ khóa trong nghĩa.
  List<Word> _rankVietnameseResults({
    required List<Map<String, Object?>> rows,
    required String normalizedKeyword,
    required List<String> tokens,
    required int limit,
  }) {
    final ranked =
        rows
            .map(_toWord)
            .map(
              (word) => _ScoredWord(
                word: word,
                score: _scoreVietnameseMatch(word, normalizedKeyword, tokens),
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

    return ranked.take(limit).map((item) => item.word).toList();
  }

  // Tìm các từ liên quan, ưu tiên các từ sát nghĩa tiếng Việt.
  Future<List<Word>> getRelatedWords(Word baseWord, {int limit = 10}) async {
    final db = await _getDatabase();
    final normalizedMeaning = _normalizeSearchText(baseWord.meaning);
    final meaningTokens = _extractMeaningTokens(baseWord.meaning);
    if (normalizedMeaning.isEmpty || meaningTokens.isEmpty) {
      return const [];
    }

    // Lấy một tập ứng viên đủ rộng theo các token trong nghĩa tiếng Việt.
    final whereParts = List.filled(meaningTokens.length, 'LOWER(meaning) LIKE ?');
    final whereClause = '${whereParts.join(' OR ')} AND word != ?';
    final whereArgs = <Object?>[
      ...meaningTokens.map((token) => '%$token%'),
      baseWord.hanzi,
    ];

    final rows = await db.query(
      'words',
      columns: ['id', 'word', 'pinyin', 'meaning'],
      where: whereClause,
      whereArgs: whereArgs,
      limit: 120,
    );

    final ranked =
        rows
            .map(_toWord)
            .where((candidate) => candidate.hanzi != baseWord.hanzi)
            .map(
              (candidate) => _ScoredWord(
                word: candidate,
                score: _scoreRelatedMeaning(
                  baseMeaning: normalizedMeaning,
                  baseTokens: meaningTokens,
                  candidateMeaning: _normalizeSearchText(candidate.meaning),
                ),
              ),
            )
            .where((item) => item.score > 0)
            .toList()
          ..sort((a, b) {
            final byScore = b.score.compareTo(a.score);
            if (byScore != 0) {
              return byScore;
            }
            return a.word.hanzi.length.compareTo(b.word.hanzi.length);
          });

    return ranked.take(limit).map((item) => item.word).toList();
  }

  Future<String?> lookMeaning(String phrase) async {
    final normalizedPhrase = phrase.trim();
    if (normalizedPhrase.isEmpty) {
      return null;
    }

    if (_meaningMap.containsKey(normalizedPhrase)) {
      return _meaningMap[normalizedPhrase];
    } // Nếu đã tra trước đó thì trả ngay kết quả cache (không query DB nữa)

    final db = await _getDatabase();
    final rows = await db.query(
      'words',
      columns: ['meaning'],
      where: 'word = ?',
      whereArgs: [normalizedPhrase],
      limit: 1,
    ); // Tra cứu nghĩa của cụm từ chính xác trong database

    final meaning = rows.isEmpty
        ? null
        : _normalizeMeaning(rows.first['meaning'] as String?);
    _meaningMap[normalizedPhrase] = meaning;
    return meaning;
  }

  // Chuẩn hóa phần nghĩa để làm gợi ý: loại bỏ chú thích trong ngoặc, chỉ lấy phần đầu tiên nếu có nhiều nghĩa, và loại bỏ các gợi ý tham chiếu hoặc không phải nghĩa thực sự.
  String? _normalizeMeaning(String? meaning) {
    if (meaning == null) {
      return null;
    }

    final firstVariant = meaning
        .split('/')
        .first
        .trim(); // Chỉ lấy phần đầu tiên của nghĩa để làm gợi ý, thường sẽ là nghĩa chính hoặc phổ biến nhất.
    if (firstVariant.isEmpty) {
      return null;
    }

    final cleaned = firstVariant
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'（[^）]*）'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim(); // Loại bỏ chú thích trong ngoặc và khoảng trắng thừa

    if (cleaned.isEmpty) {
      return null;
    }

    // Loại bỏ các gợi ý có vẻ là tham chiếu đến từ khác hoặc không phải nghĩa thực sự (ví dụ: "xem ...", chứa dấu ngoặc vuông, dấu pipe, hoặc chứa ký tự Hán).
    final looksLikeReference =
        cleaned.toLowerCase().startsWith('xem ') ||
        cleaned.contains('[') ||
        cleaned.contains(']') ||
        cleaned.contains('|') ||
        RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF]').hasMatch(cleaned);

    return looksLikeReference ? null : cleaned;
  }

  Future<Database> _getDatabase() async {
    if (_db != null) {
      return _db!;
    }

    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'dictionary.db');
    final hashPath = path.join(databasesPath, _assetHashFile);
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

    _db = await openDatabase(dbPath, readOnly: true);
    return _db!;
  }

  // Tính toán hash của file asset để kiểm tra xem có cần copy lại vào bộ nhớ trong hay không
  String _computeHash(Uint8List bytes) {
    var hash = 2166136261;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  // Chuyển một hàng từ database thành đối tượng Word
  Word _toWord(Map<String, Object?> row) {
    return Word(
      id: (row['id'] ?? '').toString(),
      hanzi: (row['word'] ?? '').toString(),
      pinyin: (row['pinyin'] ?? '').toString(),
      meaning: _normalizeMeaning((row['meaning'] ?? '').toString()) ?? '',
      hskLevel: '',
    );
  }

  // Tách các token tiếng Việt có ý nghĩa để so khớp mức độ sát nghĩa.
  List<String> _extractMeaningTokens(String meaning) {
    final normalized = _normalizeSearchText(
      meaning
          .replaceAll(RegExp(r'[()/;,\-]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' '),
    );
    if (normalized.isEmpty) {
      return const [];
    }

    const stopWords = {
      'là',
      'của',
      'và',
      'hoặc',
      'được',
      'cho',
      'với',
      'trong',
      'khi',
      'để',
      'một',
      'các',
      'những',
      'sự',
      'việc',
      'người',
      'cái',
      'con',
      'này',
      'kia',
    };

    final seen = <String>{};
    final tokens = <String>[];
    for (final token in normalized.split(' ')) {
      if (token.length < 2 || stopWords.contains(token) || seen.contains(token)) {
        continue;
      }
      seen.add(token);
      tokens.add(token);
    }
    return tokens;
  }

  int _scoreRelatedMeaning({
    required String baseMeaning,
    required List<String> baseTokens,
    required String candidateMeaning,
  }) {
    if (candidateMeaning.isEmpty) {
      return 0;
    }

    var score = 0;
    if (candidateMeaning == baseMeaning) {
      score += 1200;
    }
    if (candidateMeaning.startsWith(baseMeaning)) {
      score += 600;
    } else if (candidateMeaning.contains(baseMeaning)) {
      score += 400;
    }

    for (final token in baseTokens) {
      if (candidateMeaning.startsWith('$token ') ||
          candidateMeaning.startsWith('$token,') ||
          candidateMeaning.startsWith('$token;') ||
          candidateMeaning.startsWith('$token/')) {
        score += 220;
      } else if (candidateMeaning.contains(' $token ') ||
          candidateMeaning.contains('/$token') ||
          candidateMeaning.contains('$token/')) {
        score += 150;
      } else if (candidateMeaning.contains(token)) {
        score += 80;
      }
    }

    // Nghĩa ngắn thường sát nghĩa hơn trong danh sách gợi ý.
    return score - candidateMeaning.length ~/ 2;
  }

  // Chuẩn hóa chuỗi tìm kiếm: loại bỏ khoảng trắng thừa, chuyển về chữ thường, và thay thế nhiều khoảng trắng bằng một khoảng trắng duy nhất.
  String _normalizeSearchText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Tách cụm từ thành token để tìm kiếm (ví dụ: "ăn cơm" -> ["ăn", "cơm"])
  List<String> _tokenize(String text) {
    return text.split(' ').where((item) => item.isNotEmpty).toList();
  }

  // Điều chỉnh giới hạn gợi ý dựa trên số lượng token
  int _resolveSuggestionLimit(int tokenCount, int fallbackLimit) {
    if (tokenCount <= 1) {
      return fallbackLimit;
    }
    if (tokenCount == 2) {
      return fallbackLimit > 8 ? 8 : fallbackLimit;
    }
    return fallbackLimit > 6 ? 6 : fallbackLimit;
  }

  // Đánh giá độ ưu tiên của kết quả tìm kiếm tiếng Việt dựa trên mức độ khớp và vị trí của từ khóa trong nghĩa.
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
        .toList(); // Tách nghĩa gốc thành các phần nhỏ hơn để đánh giá độ ưu tiên
    final exactPartIndex = commaParts.indexOf(
      normalizedKeyword,
    ); // lấy vị trí của phần khớp chính xác
    if (exactPartIndex >= 0) {
      score +=
          650 -
          (exactPartIndex * 25); // vị trí càng gần đầu càng có điểm cao hơn
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
    return score - meaning.length;
  }
}

class _ScoredWord {
  final Word word;
  final int score;

  const _ScoredWord({required this.word, required this.score});
}
