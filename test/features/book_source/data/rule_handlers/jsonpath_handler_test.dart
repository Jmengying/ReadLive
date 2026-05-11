import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/rule_handlers/jsonpath_handler.dart';

void main() {
  final handler = JsonpathHandler();

  final jsonData = {
    'code': 0,
    'data': {
      'books': [
        {'name': 'Book A', 'author': 'Author 1', 'url': '/a'},
        {'name': 'Book B', 'author': 'Author 2', 'url': '/b'},
      ],
      'total': 2,
    },
  };

  group('extractText', () {
    test('simple path', () {
      final result = handler.extractText(jsonData, r'$.code');
      expect(result, '0');
    });

    test('nested path', () {
      final result = handler.extractText(jsonData, r'$.data.total');
      expect(result, '2');
    });

    test('json: prefix', () {
      final result = handler.extractText(jsonData, r'@json:$.data.total');
      expect(result, '2');
    });

    test('returns null for missing path', () {
      final result = handler.extractText(jsonData, r'$.nonexistent');
      expect(result, isNull);
    });
  });

  group('extractList', () {
    test('array field', () {
      final results = handler.extractList(jsonData, r'$.data.books[*].name');
      expect(results, ['Book A', 'Book B']);
    });

    test('returns empty for missing array', () {
      final results = handler.extractList(jsonData, r'$.missing[*].name');
      expect(results, isEmpty);
    });
  });

  group('isJsonPath', () {
    test(r'detects $. prefix', () {
      expect(JsonpathHandler.isJsonPath(r'$.data.name'), true);
    });

    test('detects @json: prefix', () {
      expect(JsonpathHandler.isJsonPath(r'@json:$.data.name'), true);
    });

    test('rejects CSS selector', () {
      expect(JsonpathHandler.isJsonPath('.class@text'), false);
    });
  });
}
