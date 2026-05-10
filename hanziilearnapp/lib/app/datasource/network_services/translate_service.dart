import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:hanziilearnapp/app/datasource/local/cn_vi_dictionary_db_service.dart';
import 'package:hanziilearnapp/app/datasource/network_services/image_translation_service.dart';
import 'package:hanziilearnapp/app/datasource/network_services/speech_translation_service.dart';
import 'package:hanziilearnapp/app/datasource/network_services/text_translation_service.dart';
import 'package:translator/translator.dart';

export 'package:hanziilearnapp/app/datasource/network_services/image_translation_service.dart'
    show ImageTranslationBlock, ImageTranslationResult;

class TranslationService {
  factory TranslationService({
    GoogleTranslator? translator,
    CnViDictionaryDbService? dictionaryDbService,
    TextTranslationService? textTranslationService,
    SpeechTranslationService? speechTranslationService,
    ImageTranslationService? imageTranslationService,
  }) {
    final txtSvc =
        textTranslationService ??
        TextTranslationService(
          translator: translator,
          dictionaryDbService: dictionaryDbService,
        );

    return TranslationService._(
      textTranslationService: txtSvc,
      speechTranslationService:
          speechTranslationService ??
          SpeechTranslationService(textService: txtSvc),
      imageTranslationService:
          imageTranslationService ??
          ImageTranslationService(textService: txtSvc),
    );
  }

  const TranslationService._({
    required TextTranslationService textTranslationService,
    required SpeechTranslationService speechTranslationService,
    required ImageTranslationService imageTranslationService,
  }) : _textTranslationService = textTranslationService,
       _speechSvc = speechTranslationService,
       _imgSvc = imageTranslationService;

  final TextTranslationService _textTranslationService;
  final SpeechTranslationService _speechSvc;
  final ImageTranslationService _imgSvc;

  Future<String> trText(
    String text, {
    required String from,
    required String to,
    TranslationMode mode = TranslationMode.balanced,
  }) {
    return _textTranslationService.trText(
      text,
      from: from,
      to: to,
      mode: mode,
    );
  }

  Future<String> trSpeech(
    String transcript, {
    required String from,
    required String to,
  }) {
    return _speechSvc.trSpeech(
      transcript,
      from: from,
      to: to,
    );
  }

  Future<ImageTranslationResult> trOcr(
    RecognizedText recognizedText, {
    required String from,
    required String to,
    TranslationMode mode = TranslationMode.strictNatural,
  }) {
    return _imgSvc.trOcr(
      recognizedText,
      from: from,
      to: to,
      mode: mode,
    );
  }
}
