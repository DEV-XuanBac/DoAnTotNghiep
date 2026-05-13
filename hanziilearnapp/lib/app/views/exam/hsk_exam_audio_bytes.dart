import 'dart:convert';

import 'package:flutter/services.dart';

/// Cache parsed `AssetManifest.json` để không decode lại JSON mỗi lần
/// fallback audio (file lớn, parse 1 lần là đủ).
Future<Map<String, dynamic>>? _manifestFuture;

Future<Map<String, dynamic>> _loadManifest() {
  return _manifestFuture ??= rootBundle
      .loadString('AssetManifest.json')
      .then((raw) => jsonDecode(raw) as Map<String, dynamic>);
}

/// Đọc bytes audio cho đề HSK (fallback qua AssetManifest khi path không khớp).
Future<ByteData> loadHskExamAudioBytes(String audioAssetPath) async {
  try {
    return await rootBundle.load(audioAssetPath);
  } catch (_) {
    final manifestMap = await _loadManifest();
    final fileName = audioAssetPath.split('/').last;

    final matchedKey = manifestMap.keys.cast<String?>().firstWhere(
      (key) => key != null && key.endsWith('/$fileName'),
      orElse: () => null,
    );

    if (matchedKey == null) {
      rethrow;
    }

    return rootBundle.load(matchedKey);
  }
}
