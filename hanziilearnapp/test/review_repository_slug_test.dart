import 'package:flutter_test/flutter_test.dart';
import 'package:hanziilearnapp/app/datasource/repository/review_repository.dart';

void main() {
  group('ReviewRepository.slug', () {
    test('trims and lowercases ASCII', () {
      expect(ReviewRepository.slug('  Hello World  '), 'hello_world');
    });

    test('replaces inner whitespace with underscore', () {
      expect(ReviewRepository.slug('a\tb\nc'), 'a_b_c');
    });

    test('keeps Vietnamese letters', () {
      expect(ReviewRepository.slug('Chủ đề 1'), 'chủ_đề_1');
    });

    test('keeps CJK', () {
      expect(ReviewRepository.slug('主题 A'), '主题_a');
    });

    test('strips disallowed characters', () {
      expect(ReviewRepository.slug('a@b#c'), 'abc');
    });
  });
}
