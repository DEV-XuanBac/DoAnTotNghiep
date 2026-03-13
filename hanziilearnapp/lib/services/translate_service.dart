import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hanziilearnapp/services/cn_vi_dictionary_db_service.dart';
import 'package:translator/translator.dart';

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

class TranslationService {
  TranslationService({
    GoogleTranslator? translator,
    CnViDictionaryDbService? dictionaryDbService,
  }) : _translator = translator ?? GoogleTranslator(),
       _dictionaryDbService = dictionaryDbService ?? CnViDictionaryDbService();

  final GoogleTranslator _translator;
  final CnViDictionaryDbService _dictionaryDbService;

  Future<String> translateText(
    String text, {
    required String from,
    required String to,
  }) async {
    var sourceText = text.trim();

    if (from == 'zh-cn' && to == 'vi') {
      final dictionaryMeaning = await _dictionaryDbService.lookupMeaning(
        sourceText,
      );
      if (dictionaryMeaning != null && sourceText.length <= 18) {
        return _postProcessTranslation(dictionaryMeaning, targetLanguage: to);
      }
    }

    final result = await _translator.translate(sourceText, from: from, to: to);
    return _postProcessTranslation(result.text, targetLanguage: to);
  }

  Future<ImageTranslationResult> translateRecognizedText(
    RecognizedText recognizedText, {
    required String from,
    required String to,
  }) async {
    final paragraphs = _extractParagraphs(recognizedText);
    if (paragraphs.isEmpty) {
      throw const FormatException('Không tách được đoạn văn từ ảnh.');
    }

    final translatedTexts = await Future.wait(
      paragraphs.map(
        (paragraph) => translateText(paragraph.sourceText, from: from, to: to),
      ),
    );

    return ImageTranslationResult(
      sourceText: paragraphs.map((item) => item.sourceText).join('\n\n'),
      translatedText: translatedTexts.join('\n\n'),
      blocks: [
        for (int i = 0; i < paragraphs.length; i++)
          ImageTranslationBlock(
            boundingBox: paragraphs[i].boundingBox,
            translatedText: translatedTexts[i],
          ),
      ],
    );
  }

  List<_OcrParagraph> _extractParagraphs(RecognizedText recognizedText) {
    final lines =
        recognizedText.blocks
            .expand((block) => block.lines)
            .map(
              (line) => _OcrLine(
                text: _normalizeOcrText(line.text),
                boundingBox: line.boundingBox,
              ),
            )
            .where((line) => line.text.isNotEmpty)
            .toList()
          ..sort((a, b) => _compareRects(a.boundingBox, b.boundingBox));

    if (lines.isEmpty) {
      return const [];
    }

    final paragraphs = <List<_OcrLine>>[
      [lines.first],
    ];

    for (int i = 1; i < lines.length; i++) {
      final previousLine = paragraphs.last.last;
      final currentLine = lines[i];
      if (_shouldStartNewParagraph(
        previousLine: previousLine,
        currentLine: currentLine,
        currentParagraphFirstLine: paragraphs.last.first,
      )) {
        paragraphs.add([currentLine]);
      } else {
        paragraphs.last.add(currentLine);
      }
    }

    return paragraphs
        .map(
          (paragraphLines) => _OcrParagraph(
            boundingBox: _combineRects(
              paragraphLines.map((line) => line.boundingBox),
            ),
            sourceText: _joinOcrLinesForTranslation(
              paragraphLines.map((line) => line.text),
            ),
          ),
        )
        .toList();
  }

  int _compareRects(Rect a, Rect b) {
    const verticalTolerance = 12.0;
    if ((a.top - b.top).abs() <= verticalTolerance) {
      return a.left.compareTo(b.left);
    }
    return a.top.compareTo(b.top);
  }

  Rect _combineRects(Iterable<Rect> rects) {
    final rectList = rects.toList();
    if (rectList.isEmpty) return Rect.zero;

    double left = rectList.first.left;
    double top = rectList.first.top;
    double right = rectList.first.right;
    double bottom = rectList.first.bottom;

    for (final rect in rectList.skip(1)) {
      left = math.min(left, rect.left);
      top = math.min(top, rect.top);
      right = math.max(right, rect.right);
      bottom = math.max(bottom, rect.bottom);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  double _horizontalOverlapRatio(Rect a, Rect b) {
    final overlap = math.max(
      0.0,
      math.min(a.right, b.right) - math.max(a.left, b.left),
    );
    final baseWidth = math.min(a.width, b.width);
    if (baseWidth <= 0) return 0;
    return overlap / baseWidth;
  }

  bool _shouldStartNewParagraph({
    required _OcrLine previousLine,
    required _OcrLine currentLine,
    required _OcrLine currentParagraphFirstLine,
  }) {
    final verticalGap =
        currentLine.boundingBox.top - previousLine.boundingBox.bottom;
    final averageHeight =
        (previousLine.boundingBox.height + currentLine.boundingBox.height) / 2;
    final leftDifference =
        (currentLine.boundingBox.left -
                currentParagraphFirstLine.boundingBox.left)
            .abs();
    final overlap = _horizontalOverlapRatio(
      previousLine.boundingBox,
      currentLine.boundingBox,
    );

    final hasStrongGap = verticalGap > averageHeight * 1.2;
    final hasParagraphGap = verticalGap > averageHeight * 0.75;
    final hasColumnBreak =
        overlap < 0.2 && leftDifference > averageHeight * 1.8;
    final previousEndsParagraph = _endsParagraph(previousLine.text);

    if (hasStrongGap || hasColumnBreak) {
      return true;
    }

    if (previousEndsParagraph) {
      return hasParagraphGap;
    }

    return false;
  }

  bool _endsParagraph(String text) {
    return RegExp(
      r'[.!?;\u3002\uFF01\uFF1F\uFF1B\uFF1A:]$',
    ).hasMatch(text.trim());
  }

  String _normalizeOcrText(String text) {
    final normalized = text
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAllMapped(
          RegExp(r' *([,.;:!?])'),
          (match) => match.group(1) ?? '',
        )
        .trim();

    return _removeSpacesBetweenCjk(normalized);
  }

  String _joinOcrLinesForTranslation(Iterable<String> lines) {
    final lineList = lines
        .map(_normalizeOcrText)
        .where((line) => line.isNotEmpty)
        .toList();

    if (lineList.isEmpty) {
      return '';
    }

    final combined = lineList.join();
    if (_isCjkDominantText(combined)) {
      return lineList.map(_removeSpacesBetweenCjk).join();
    }

    return lineList.join(' ');
  }

  bool _isCjkDominantText(String text) {
    final cjkMatches = RegExp(r'[\u3400-\u4DBF\u4E00-\u9FFF]').allMatches(text);
    final latinMatches = RegExp(r'[A-Za-z]').allMatches(text);

    return cjkMatches.length > latinMatches.length;
  }

  String _removeSpacesBetweenCjk(String text) {
    var result = text;
    final pattern = RegExp(
      r'([\u3400-\u4DBF\u4E00-\u9FFF])\s+([\u3400-\u4DBF\u4E00-\u9FFF])',
    );

    while (pattern.hasMatch(result)) {
      result = result.replaceAllMapped(
        pattern,
        (match) => '${match.group(1) ?? ''}${match.group(2) ?? ''}',
      );
    }

    return result;
  }

  String _postProcessTranslation(
    String text, {
    required String targetLanguage,
  }) {
    final normalizedBreaks = text.replaceAll('\r\n', '\n').trim();
    final paragraphs = normalizedBreaks
        .split(RegExp(r'\n{2,}'))
        .map(
          (paragraph) => _normalizeTranslatedParagraph(
            paragraph,
            targetLanguage: targetLanguage,
          ),
        )
        .where((paragraph) => paragraph.isNotEmpty)
        .toList();

    return paragraphs.join('\n\n').trim();
  }

  String _normalizeTranslatedParagraph(
    String text, {
    required String targetLanguage,
  }) {
    var normalized = text
        .replaceAll(RegExp(r'\s*\n\s*'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAllMapped(
          RegExp(r'\s+([,.;:!?])'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll('( ', '(')
        .replaceAll('[ ', '[')
        .replaceAll('{ ', '{')
        .replaceAll(' )', ')')
        .replaceAll(' ]', ']')
        .replaceAll(' }', '}')
        .trim();

    if (targetLanguage == 'vi') {
      normalized = _capitalizeFirstLetter(normalized);
    }

    return normalized;
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;

    final firstLetterIndex = text.indexOf(RegExp(r'\S'));
    if (firstLetterIndex < 0) return text;

    final prefix = text.substring(0, firstLetterIndex);
    final firstLetter = text[firstLetterIndex].toUpperCase();
    final suffix = text.substring(firstLetterIndex + 1);

    return '$prefix$firstLetter$suffix';
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
