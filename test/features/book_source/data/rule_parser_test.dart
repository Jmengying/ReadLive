import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/rule_parser.dart';

void main() {
  final parser = RuleParser();

  group('resolveTemplate', () {
    test('replaces single variable', () {
      final result = parser.resolveTemplate(
        'https://example.com/search?kw={{key}}',
        {'key': 'test'},
      );
      expect(result, 'https://example.com/search?kw=test');
    });

    test('replaces multiple variables', () {
      final result = parser.resolveTemplate(
        '{{host}}/search?kw={{key}}&p={{page}}',
        {'host': 'https://a.com', 'key': 'novel', 'page': '1'},
      );
      expect(result, 'https://a.com/search?kw=novel&p=1');
    });

    test('leaves unmatched variables as-is', () {
      final result = parser.resolveTemplate('{{key}}-{{missing}}', {'key': 'a'});
      expect(result, 'a-{{missing}}');
    });
  });

  group('extractText', () {
    test('extracts text from CSS selector', () {
      const html = '<html><body><div class="title">Hello World</div></body></html>';
      final result = parser.extractText(html, '.title');
      expect(result, 'Hello World');
    });

    test('returns null for missing element', () {
      const html = '<html><body><div>Hi</div></body></html>';
      final result = parser.extractText(html, '.missing');
      expect(result, isNull);
    });

    test('applies @text extraction', () {
      const html = '<html><body><a href="/link">Link Text</a></body></html>';
      final result = parser.extractText(html, 'a@text');
      expect(result, 'Link Text');
    });

    test('applies @href extraction', () {
      const html = '<html><body><a href="/chapter/1">Ch1</a></body></html>';
      final result = parser.extractText(html, 'a@href');
      expect(result, '/chapter/1');
    });

    test('applies @src extraction', () {
      const html = '<html><body><img src="/cover.jpg"/></body></html>';
      final result = parser.extractText(html, 'img@src');
      expect(result, '/cover.jpg');
    });

    test('applies |trim filter', () {
      const html = '<html><body><div class="t">  spaced  </div></body></html>';
      final result = parser.extractText(html, '.t@text|trim');
      expect(result, 'spaced');
    });

    test('applies |replace filter', () {
      const html = '<html><body><div class="t">hello world</div></body></html>';
      final result = parser.extractText(html, '.t@text|replace(hello,hi)');
      expect(result, 'hi world');
    });
  });

  group('extractList', () {
    test('extracts list of values', () {
      const html = '''
        <html><body>
          <ul>
            <li class="ch"><a href="/1">Chapter 1</a></li>
            <li class="ch"><a href="/2">Chapter 2</a></li>
            <li class="ch"><a href="/3">Chapter 3</a></li>
          </ul>
        </body></html>
      ''';
      final results = parser.extractList(html, '.ch a', '@text');
      expect(results, ['Chapter 1', 'Chapter 2', 'Chapter 3']);
    });

    test('extracts list of hrefs', () {
      const html = '''
        <html><body>
          <ul>
            <li class="ch"><a href="/1">Ch1</a></li>
            <li class="ch"><a href="/2">Ch2</a></li>
          </ul>
        </body></html>
      ''';
      final results = parser.extractList(html, '.ch a', '@href');
      expect(results, ['/1', '/2']);
    });

    test('returns empty list for no matches', () {
      const html = '<html><body><div>Hi</div></body></html>';
      final results = parser.extractList(html, '.missing', '@text');
      expect(results, isEmpty);
    });
  });

  group('extractContent', () {
    test('extracts full text content with |trim|removeAd', () {
      const html = '''
        <html><body>
          <div class="content">
            <p>Paragraph one.</p>
            <p>Paragraph two.</p>
            <script>ad code</script>
          </div>
        </body></html>
      ''';
      final result = parser.extractContent(html, '.content@text|trim|removeAd');
      expect(result, contains('Paragraph one'));
      expect(result, contains('Paragraph two'));
      expect(result, isNot(contains('ad code')));
    });
  });
}
