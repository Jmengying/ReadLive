import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/data/rule_parser.dart';
import 'package:readlive/features/book_source/domain/source_rule.dart';

void main() {
  final extractor = ContentExtractor(ruleParser: RuleParser());

  group('extractSearchResults', () {
    test('extracts search result list', () {
      const html = '''
        <html><body>
          <div class="result-item">
            <a class="title" href="/book/1">Novel One</a>
            <span class="author">Author A</span>
            <img class="cover" src="/cover1.jpg"/>
            <p class="desc">A great novel</p>
          </div>
          <div class="result-item">
            <a class="title" href="/book/2">Novel Two</a>
            <span class="author">Author B</span>
          </div>
        </body></html>
      ''';

      final rule = SearchRule(
        url: 'https://example.com/search',
        list: '.result-item',
        bookName: '.title@text',
        author: '.author@text',
        cover: '.cover@src',
        intro: '.desc@text',
        bookUrl: '.title@href',
      );

      final results = extractor.extractSearchResults(html, rule, 'src-1', 'Test Source');
      expect(results.length, 2);
      expect(results[0].bookName, 'Novel One');
      expect(results[0].author, 'Author A');
      expect(results[0].bookUrl, '/book/1');
      expect(results[1].bookName, 'Novel Two');
    });
  });

  group('extractSearchResults from JSON', () {
    test('extracts search results from JSON API response', () {
      const jsonBody = '''
      {
        "data": [
          {"name": "斗破苍穹", "author": "天蚕土豆", "url": "/book/1"},
          {"name": "武动乾坤", "author": "天蚕土豆", "url": "/book/2"}
        ]
      }
      ''';

      final rule = SearchRule(
        url: 'https://example.com/api/search',
        list: r'$.data[*]',
        bookName: r'$.name',
        author: r'$.author',
        bookUrl: r'$.url',
      );

      final results = extractor.extractSearchResults(jsonBody, rule, 'src-1', 'API Source');
      expect(results.length, 2);
      expect(results[0].bookName, '斗破苍穹');
      expect(results[0].author, '天蚕土豆');
      expect(results[0].bookUrl, '/book/1');
    });
  });

  group('extractToc', () {
    test('extracts chapter list', () {
      const html = '''
        <html><body>
          <ul class="chapter-list">
            <li><a href="/ch/1">Chapter 1</a></li>
            <li><a href="/ch/2">Chapter 2</a></li>
            <li><a href="/ch/3">Chapter 3</a></li>
          </ul>
        </body></html>
      ''';

      final rule = TocRule(
        list: '.chapter-list li a',
        name: '@text',
        url: '@href',
      );

      final chapters = extractor.extractToc(html, rule);
      expect(chapters.length, 3);
      expect(chapters[0].title, 'Chapter 1');
      expect(chapters[0].url, '/ch/1');
      expect(chapters[2].title, 'Chapter 3');
    });
  });

  group('extractContent', () {
    test('extracts chapter text', () {
      const html = '''
        <html><body>
          <div class="content">
            <p>First paragraph.</p>
            <p>Second paragraph.</p>
            <div class="ad">广告内容</div>
          </div>
        </body></html>
      ''';

      final rule = ContentRule(
        content: '.content@text|trim|removeAd',
      );

      final text = extractor.extractChapterContent(html, rule);
      expect(text, contains('First paragraph'));
      expect(text, contains('Second paragraph'));
      expect(text, isNot(contains('广告')));
    });
  });
}
