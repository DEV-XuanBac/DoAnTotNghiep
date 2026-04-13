class Word {
  final String id;
  final String hanzi;
  final String pinyin;
  final String meaning;
  final String hskLevel;
  final String stt;
  final String topic;
  final String ttsUrl;
  final String exampleHanzi;
  final String examplePinyin;
  final String exampleMeaning;

  Word({
    required this.id,
    required this.hanzi,
    required this.pinyin,
    required this.meaning,
    required this.hskLevel,
    this.stt = '',
    this.topic = '',
    this.ttsUrl = '',
    this.exampleHanzi = '',
    this.examplePinyin = '',
    this.exampleMeaning = '',
  });
}
