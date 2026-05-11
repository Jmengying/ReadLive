import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/rule_handlers/xpath_handler.dart';

void main() {
  final handler = XpathHandler();

  const html = '''
    <html>
      <body>
        <div class="book-list">
          <div class="book">
            <a href="/book/1">Book One</a>
            <span class="author">Author A</span>
          </div>
          <div class="book">
            <a href="/book/2">Book Two</a>
            <span class="author">Author B</span>
          </div>
        </div>
        <div id="info">
          <h1>Title</h1>
          <p>Introduction text</p>
        </div>
      </body>
    </html>
  ''';

  group('extractText', () {
    test('simple tag', () {
      final result = handler.extractText(html, '//h1');
      expect(result, 'Title');
    });

    test('tag with attribute filter', () {
      final result = handler.extractText(html, """//div[@class='book']/a""");
      expect(result, 'Book One');
    });

    test('id selector', () {
      final result = handler.extractText(html, """//*[@id='info']/h1""");
      expect(result, 'Title');
    });

    test('text() accessor', () {
      final result = handler.extractText(html, '//h1/text()');
      expect(result, 'Title');
    });

    test('href attribute', () {
      final result =
          handler.extractText(html, """//div[@class='book']/a/@href""");
      expect(result, '/book/1');
    });
  });

  group('extractList', () {
    test('multiple elements', () {
      final results =
          handler.extractList(html, """//div[@class='book']/a""");
      expect(results, ['Book One', 'Book Two']);
    });

    test('attribute list', () {
      final results =
          handler.extractList(html, """//div[@class='book']/a/@href""");
      expect(results, ['/book/1', '/book/2']);
    });
  });
}
