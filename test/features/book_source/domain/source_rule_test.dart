import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/domain/source_rule.dart';

void main() {
  test('SourceRule.fromJson parses complete rule', () {
    final json = jsonDecode('''
    {
      "id": "test-1",
      "name": "Test Source",
      "host": "https://example.com",
      "contentType": "novel",
      "enabled": true,
      "weight": 100,
      "search": {
        "url": "https://example.com/search?kw={{key}}&page={{page}}",
        "list": ".result-item",
        "bookName": ".title@text",
        "author": ".author@text",
        "cover": ".img@src",
        "intro": ".desc@text",
        "bookUrl": ".title@href"
      },
      "bookInfo": {
        "cover": ".cover@src",
        "intro": ".intro@text",
        "author": ".author@text",
        "tocUrl": "{{bookUrl}}/catalog"
      },
      "toc": {
        "list": ".chapter li a",
        "name": "@text",
        "url": "@href"
      },
      "content": {
        "content": ".content@text|trim|removeAd",
        "nextPage": ".next@href",
        "encoding": "utf-8"
      }
    }
    ''');

    final rule = SourceRule.fromJson(json as Map<String, dynamic>);
    expect(rule.name, 'Test Source');
    expect(rule.host, 'https://example.com');
    expect(rule.search, isNotNull);
    expect(rule.search!.url, contains('{{key}}'));
    expect(rule.search!.list, '.result-item');
    expect(rule.toc, isNotNull);
    expect(rule.toc!.list, '.chapter li a');
    expect(rule.content, isNotNull);
    expect(rule.content!.content, '.content@text|trim|removeAd');
  });

  test('SourceRule.fromJson handles minimal rule', () {
    final json = <String, dynamic>{
      'name': 'Minimal',
      'host': 'https://min.com',
      'search': {'list': '.r', 'bookName': '.t@text', 'bookUrl': '.t@href'},
    };
    final rule = SourceRule.fromJson(json);
    expect(rule.name, 'Minimal');
    expect(rule.search, isNotNull);
    expect(rule.bookInfo, isNull);
    expect(rule.toc, isNull);
    expect(rule.content, isNull);
  });

  test('SourceRule.toJson roundtrip', () {
    final json = <String, dynamic>{
      'name': 'Round',
      'host': 'https://round.com',
      'search': {'list': '.r', 'bookName': '.t@text', 'bookUrl': '.t@href'},
      'toc': {'list': '.ch a', 'name': '@text', 'url': '@href'},
    };
    final rule = SourceRule.fromJson(json);
    final exported = rule.toJson();
    final rule2 = SourceRule.fromJson(exported);
    expect(rule2.name, rule.name);
    expect(rule2.toc!.list, rule.toc!.list);
  });
}
