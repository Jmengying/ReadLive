import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/search_service.dart';

void main() {
  group('SearchUrlResolver', () {
    test('resolves GET URL with key encoding', () {
      final result = SearchUrlResolver.resolve(
        'https://example.com/search?q={{key}}&page={{page}}',
        '斗破苍穹',
        'https://example.com',
      );
      expect(result.isPost, false);
      expect(result.url, contains('q=%E6%96%97%E7%A0%B4'));
      expect(result.url, contains('page=1'));
      expect(result.body, isNull);
    });

    test('resolves POST form body', () {
      final result = SearchUrlResolver.resolve(
        r'@post:https://example.com/search,key={{key}}&page={{page}}',
        'test',
        'https://example.com',
      );
      expect(result.isPost, true);
      expect(result.url, 'https://example.com/search');
      expect(result.body, contains('key='));
      expect(result.body, contains('page=1'));
    });

    test('resolves POST JSON body', () {
      final result = SearchUrlResolver.resolve(
        r'@post:https://example.com/api/search,{"q":"{{key}}","page":1}',
        'test',
        'https://example.com',
      );
      expect(result.isPost, true);
      expect(result.url, 'https://example.com/api/search');
      expect(result.body, contains('"q"'));
    });

    test('resolves @Header with URL', () {
      final result = SearchUrlResolver.resolve(
        '@Header:Cookie=abc123\nhttps://example.com/search?q={{key}}',
        'test',
        'https://example.com',
      );
      expect(result.headers, isNotNull);
      expect(result.headers!['Cookie'], 'abc123');
      expect(result.url, contains('example.com/search'));
    });

    test('resolves relative URL against host', () {
      final result = SearchUrlResolver.resolve(
        '/search?q={{key}}',
        'test',
        'https://example.com',
      );
      expect(result.url, 'https://example.com/search?q=test');
    });

    test('resolves @post: with body containing commas', () {
      final result = SearchUrlResolver.resolve(
        r'@post:https://example.com/api,a=1,b=2,c={{key}}',
        'test',
        'https://example.com',
      );
      expect(result.isPost, true);
      expect(result.url, 'https://example.com/api');
      expect(result.body, 'a=1,b=2,c=test');
    });
  });
}
