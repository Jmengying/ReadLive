import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
import 'package:readlive/features/book_source/data/rule_parser.dart';
import 'package:readlive/features/book_source/domain/source_rule.dart';

void main() {
  group('Legado integration', () {
    final parser = RuleParser();
    final extractor = ContentExtractor(ruleParser: parser);

    test('CSS selector extraction works as before', () async {
      const html = '''
        <html><body>
          <div class="book-list">
            <div class="book"><a href="/1">Book A</a></div>
            <div class="book"><a href="/2">Book B</a></div>
          </div>
        </body></html>
      ''';
      final results = await extractor.extractSearchResults(
        html,
        SearchRule(url: '', list: '.book', bookName: 'a@text', bookUrl: 'a@href'),
        'src1',
        'Test Source',
      );
      expect(results.length, 2);
      expect(results[0].bookName, 'Book A');
      expect(results[0].bookUrl, '/1');
    });

    test('JSONPath extraction from JSON data', () {
      final jsonData = {
        'data': {
          'list': [
            {'name': 'Book A', 'url': '/a'},
            {'name': 'Book B', 'url': '/b'},
          ],
        },
      };
      final names = parser.extractListFromJson(jsonData, r'$.data.list[*].name');
      expect(names, ['Book A', 'Book B']);
    });

    test('variable @put/@get across rules', () {
      final ctx = RuleContext();
      const html = '<html><body><div class="title">My Book</div></body></html>';
      parser.extractText(html, '.title@text@put:{bookTitle=My Book}', context: ctx);
      expect(ctx.get('bookTitle'), 'My Book');
    });

    test('connector && merges values', () {
      const html = '''
        <html><body>
          <div class="a">A</div>
          <div class="b">B</div>
        </body></html>
      ''';
      final result = parser.extractText(html, '.a@text&&.b@text');
      expect(result, contains('A'));
      expect(result, contains('B'));
    });

    test('connector || returns first non-empty', () {
      const html = '<html><body><div class="exists">Found</div></body></html>';
      final result = parser.extractText(html, '.missing@text||.exists@text');
      expect(result, 'Found');
    });

    test('XPath extraction', () {
      const html = '<html><body><h1>Title</h1></body></html>';
      final result = parser.extractTextWithXpath(html, '//h1');
      expect(result, 'Title');
    });

    test('Regex AllInOne in list extraction', () {
      const html = '<html><body><a href="/1">A</a><a href="/2">B</a></body></html>';
      final results = parser.extractList(html, 'html', r':href="([^"]+)"');
      expect(results, ['/1', '/2']);
    });

    test('RuleContext isolation between tests', () {
      final ctx1 = RuleContext()..put('k', 'v1');
      final ctx2 = RuleContext()..put('k', 'v2');
      expect(ctx1.get('k'), 'v1');
      expect(ctx2.get('k'), 'v2');
    });
  });
}
