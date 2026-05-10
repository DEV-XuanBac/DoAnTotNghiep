import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hanziilearnapp/app/datasource/network_services/text_translation_service.dart';

class ImageTranslationBlock {
  final Rect boundingBox;
  final String translatedText;

  const ImageTranslationBlock({
    required this.boundingBox,
    required this.translatedText,
  });
}

class ImageTranslationResult {
  final String sourceText;
  final String translatedText;
  final List<ImageTranslationBlock> blocks;

  const ImageTranslationResult({
    required this.sourceText,
    required this.translatedText,
    required this.blocks,
  });
}

class ImageTranslationService {
  const ImageTranslationService({required TextTranslationService textService})
    : _txtSvc = textService;

  final TextTranslationService _txtSvc;

  static final _lineEnd = RegExp(r'[.!?;\u3002\uFF01\uFF1F\uFF1B\uFF1A:]$');
  static final _spaceTab = RegExp(r'[ \t]+');
  static final _punctSpace = RegExp(r' *([,.;:!?])');
  static final _cjk = RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF]');
  static final _cjkSpaceCjk = RegExp(
    r'([\u3400-\u4DBF\u4E00-\u9FFF])\s+([\u3400-\u4DBF\u4E00-\u9FFF])',
  );

  Future<ImageTranslationResult> trOcr(
    RecognizedText recognizedText, {
    required String from,
    required String to,
    TranslationMode mode = TranslationMode.strictNatural,
  }) async {
    final paras = _extractParagraphs(recognizedText);
    if (paras.isEmpty) {
      throw const FormatException('Không tách được đoạn văn từ ảnh.');
    }

    final translated = await Future.wait(
      paras.map(
        (p) => _txtSvc.trText(
          p.sourceText,
          from: from,
          to: to,
          mode: mode,
        ),
      ),
    );

    return ImageTranslationResult(
      sourceText: paras.map((p) => p.sourceText).join('\n\n'),
      translatedText: translated.join('\n\n'),
      blocks: [
        for (var i = 0; i < paras.length; i++)
          ImageTranslationBlock(
            boundingBox: paras[i].boundingBox,
            translatedText: translated[i],
          ),
      ],
    );
  }

  List<_OcrParagraph> _extractParagraphs(RecognizedText recognizedText) {
    final lines = recognizedText.blocks
        .expand((b) => b.lines)
        .map(
          (line) => _OcrLine(
            text: _normalizeOcrText(line.text),
            boundingBox: line.boundingBox,
          ),
        )
        .where((line) => line.text.isNotEmpty)
        .toList()
      ..sort((a, b) => _compareRects(a.boundingBox, b.boundingBox));

    if (lines.isEmpty) return const [];

    final groups = <List<_OcrLine>>[[lines.first]];
    for (var i = 1; i < lines.length; i++) {
      final prev = groups.last.last;
      final cur = lines[i];
      if (_shouldStartNewParagraph(
            previousLine: prev,
            currentLine: cur,
            currentParagraphFirstLine: groups.last.first,
          )) {
        groups.add([cur]);
      } else {
        groups.last.add(cur);
      }
    }

    return groups
        .map(
          (g) => _OcrParagraph(
            boundingBox: _combineRects(g.map((l) => l.boundingBox)),
            sourceText: _joinOcrLinesForTranslation(g.map((l) => l.text)),
          ),
        )
        .toList();
  }

  int _compareRects(Rect a, Rect b) {
    const tol = 12.0;
    return (a.top - b.top).abs() <= tol ? a.left.compareTo(b.left) : a.top.compareTo(b.top);
  }

  Rect _combineRects(Iterable<Rect> rects) {
    final list = rects.toList();
    if (list.isEmpty) return Rect.zero;
    var l = list.first.left, t = list.first.top, r = list.first.right, bt = list.first.bottom;
    for (final x in list.skip(1)) {
      l = math.min(l, x.left);
      t = math.min(t, x.top);
      r = math.max(r, x.right);
      bt = math.max(bt, x.bottom);
    }
    return Rect.fromLTRB(l, t, r, bt);
  }

  double _horizontalOverlapRatio(Rect a, Rect b) {
    final ov = math.max(0.0, math.min(a.right, b.right) - math.max(a.left, b.left));
    final w = math.min(a.width, b.width);
    return w <= 0 ? 0 : ov / w;
  }

  bool _shouldStartNewParagraph({
    required _OcrLine previousLine,
    required _OcrLine currentLine,
    required _OcrLine currentParagraphFirstLine,
  }) {
    final gap = currentLine.boundingBox.top - previousLine.boundingBox.bottom;
    final h = (previousLine.boundingBox.height + currentLine.boundingBox.height) / 2;
    final leftDiff =
        (currentLine.boundingBox.left - currentParagraphFirstLine.boundingBox.left).abs();
    final ov = _horizontalOverlapRatio(previousLine.boundingBox, currentLine.boundingBox);

    if (gap > h * 1.2 || (ov < 0.2 && leftDiff > h * 1.8)) return true;
    if (_endsParagraph(previousLine.text)) return gap > h * 0.75;
    return false;
  }

  bool _endsParagraph(String text) => _lineEnd.hasMatch(text.trim());

  String _normalizeOcrText(String text) {
    final n = text
        .replaceAll('\r', '\n')
        .replaceAll(_spaceTab, ' ')
        .replaceAllMapped(_punctSpace, (m) => m.group(1) ?? '')
        .trim();
    return _removeSpacesBetweenCjk(n);
  }

  String _joinOcrLinesForTranslation(Iterable<String> lines) {
    final list = lines.map(_normalizeOcrText).where((s) => s.isNotEmpty).toList();
    if (list.isEmpty) return '';
    final joined = list.join();
    return _isCjkDominantText(joined) ? list.map(_removeSpacesBetweenCjk).join() : list.join(' ');
  }

  bool _isCjkDominantText(String text) =>
      _cjk.allMatches(text).length > RegExp(r'[A-Za-z]').allMatches(text).length;

  String _removeSpacesBetweenCjk(String text) {
    var s = text;
    while (_cjkSpaceCjk.hasMatch(s)) {
      s = s.replaceAllMapped(
        _cjkSpaceCjk,
        (m) => '${m.group(1) ?? ''}${m.group(2) ?? ''}',
      );
    }
    return s;
  }
}

class _OcrLine {
  final String text;
  final Rect boundingBox;

  const _OcrLine({required this.text, required this.boundingBox});
}

class _OcrParagraph {
  final Rect boundingBox;
  final String sourceText;

  const _OcrParagraph({required this.boundingBox, required this.sourceText});
}
