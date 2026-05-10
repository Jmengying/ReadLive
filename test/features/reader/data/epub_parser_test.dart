import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/reader/data/epub_parser.dart';

void main() {
  test('EpubParser class exists and can be instantiated', () {
    final parser = EpubParser();
    expect(parser, isNotNull);
  });
}
