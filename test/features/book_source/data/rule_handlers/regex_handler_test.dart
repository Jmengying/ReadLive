import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/rule_handlers/regex_handler.dart';

void main() {
  final handler = RegexHandler();

  group('extractAllInOne', () {
    test('extracts all matches with capture group', () {
      const content = '<a href="/ch1">Chapter 1</a><a href="/ch2">Chapter 2</a>';
      final results = handler.extractAllInOne(content, r'href="([^"]+)"');
      expect(results, ['/ch1', '/ch2']);
    });

    test('extracts full match when no capture group', () {
      const content = 'item1 item2 item3';
      final results = handler.extractAllInOne(content, r'item\d');
      expect(results, ['item1', 'item2', 'item3']);
    });

    test('returns empty for no matches', () {
      final results = handler.extractAllInOne('hello', r'xyz');
      expect(results, isEmpty);
    });
  });

  group('applyOnlyOne', () {
    test('replaces first match with capture group substitution', () {
      const content = 'Price: 100 USD, Price: 200 USD';
      final result = handler.applyOnlyOne(content, r'Price: (\d+) USD', r'$1元');
      expect(result, '100元');
    });

    test('returns original if no match', () {
      final result = handler.applyOnlyOne('hello', r'(\d+)', r'$1');
      expect(result, 'hello');
    });
  });

  group('applyPurify', () {
    test('replaces all matches iteratively', () {
      const content = 'Hello <b>World</b> <i>Test</i>';
      final result = handler.applyPurify(content, r'<[^>]+>', '');
      expect(result, 'Hello World Test');
    });

    test('handles replacement with capture groups', () {
      const content = 'aabbcc';
      final result = handler.applyPurify(content, r'(a+)', r'A');
      expect(result, 'Abbcc');
    });
  });

  group('parseOnlyOneRule', () {
    test('parses ##regex##replacement### format', () {
      final result = RegexHandler.parseOnlyOneRule(r'##(\d+)##num$1###');
      expect(result, isNotNull);
      expect(result!.regex, r'(\d+)');
      expect(result.replacement, r'num$1');
    });

    test('returns null for invalid format', () {
      expect(RegexHandler.parseOnlyOneRule('not a rule'), isNull);
    });
  });

  group('parsePurifyRule', () {
    test('parses ##regex##replacement format', () {
      final result = RegexHandler.parsePurifyRule(r'##<[^>]+>##');
      expect(result, isNotNull);
      expect(result!.regex, r'<[^>]+>');
      expect(result.replacement, '');
    });
  });

  group('static detection', () {
    test('isAllInOne', () {
      expect(RegexHandler.isAllInOne(r':href="([^"]+)"'), true);
      expect(RegexHandler.isAllInOne('.class@text'), false);
    });

    test('isOnlyOne', () {
      expect(RegexHandler.isOnlyOne(r'##(\d+)##num###'), true);
      expect(RegexHandler.isOnlyOne(r'##<[^>]+>##'), false);
    });

    test('isPurify', () {
      expect(RegexHandler.isPurify(r'##<[^>]+>##'), true);
      expect(RegexHandler.isPurify(r'##(\d+)##num###'), false);
    });
  });
}
