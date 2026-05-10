import 'package:hanziilearnapp/app/datasource/network_services/text_translation_service.dart';

class SpeechTranslationService {
  const SpeechTranslationService({required TextTranslationService textService})
    : _txtSvc = textService;

  final TextTranslationService _txtSvc;

  Future<String> trSpeech(
    String transcript, {
    required String from,
    required String to,
  }) {
    return _txtSvc.trText(transcript, from: from, to: to);
  }
}
