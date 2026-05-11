import 'dart:convert';
import 'package:readlive/features/book_source/data/rule_context.dart';
import 'package:readlive/features/book_source/data/rule_parser.dart';
import 'package:readlive/features/book_source/data/rule_handlers/jsonpath_handler.dart';
import 'package:readlive/features/book_source/domain/search_result.dart';
import 'package:readlive/features/book_source/domain/source_rule.dart';

class ContentExtractor {
  final RuleParser _parser;
  final JsonpathHandler _jsonpathHandler = JsonpathHandler();

  ContentExtractor({RuleParser? ruleParser}) : _parser = ruleParser ?? RuleParser();

  /// Extract search results from HTML or JSON.
  List<SearchResult> extractSearchResults(
    String body,
    SearchRule rule,
    String sourceId,
    String sourceName, {
    RuleContext? context,
  }) {
    final tableRules = <String, String>{};
    if (rule.bookName != null) tableRules['bookName'] = rule.bookName!;
    if (rule.author != null) tableRules['author'] = rule.author!;
    if (rule.cover != null) tableRules['cover'] = rule.cover!;
    if (rule.intro != null) tableRules['intro'] = rule.intro!;
    if (rule.bookUrl != null) tableRules['bookUrl'] = rule.bookUrl!;

    final rows = _parser.extractTable(body, rule.list, tableRules, context: context);

    return rows.map((row) {
      return SearchResult(
        bookName: row['bookName'] ?? '',
        author: row['author'],
        cover: row['cover'],
        intro: row['intro'],
        bookUrl: row['bookUrl'] ?? '',
        sourceId: sourceId,
        sourceName: sourceName,
      );
    }).where((r) => r.bookName.isNotEmpty && r.bookUrl.isNotEmpty).toList();
  }

  /// Extract book info from a book detail page.
  BookInfo extractBookInfo(String html, BookInfoRule rule, {RuleContext? context}) {
    return BookInfo(
      cover: rule.cover != null ? _parser.extractText(html, rule.cover!, context: context) : null,
      intro: rule.intro != null ? _parser.extractText(html, rule.intro!, context: context) : null,
      author: rule.author != null ? _parser.extractText(html, rule.author!, context: context) : null,
      tocUrl: rule.tocUrl != null
          ? _parser.resolveTemplate(rule.tocUrl!, {}, context: context)
          : null,
    );
  }

  /// Extract table of contents (chapter list) from HTML.
  List<TocEntry> extractToc(String html, TocRule rule, {RuleContext? context}) {
    final names = _parser.extractList(html, rule.list, rule.name, context: context);
    final urls = _parser.extractList(html, rule.list, rule.url, context: context);

    final entries = <TocEntry>[];
    final count = names.length < urls.length ? names.length : urls.length;
    for (var i = 0; i < count; i++) {
      entries.add(TocEntry(title: names[i], url: urls[i]));
    }
    return entries;
  }

  /// Extract chapter text content from HTML.
  String extractChapterContent(String html, ContentRule rule, {RuleContext? context}) {
    return _parser.extractContent(html, rule.content, context: context);
  }

  /// Extract image URLs from a manga chapter page.
  ///
  /// [imagesRule] is a CSS selector for image elements, e.g. `.chapter-content img`
  List<String> extractImageUrls(String html, String? imagesRule) {
    if (imagesRule == null || imagesRule.isEmpty) return [];
    return _parser.extractImageList(html, imagesRule, '@src');
  }

  /// Check if there is a next page URL.
  String? extractNextPageUrl(String html, String? nextPageRule, {RuleContext? context}) {
    if (nextPageRule == null || nextPageRule.isEmpty) return null;
    return _parser.extractText(html, nextPageRule, context: context);
  }
}

class BookInfo {
  final String? cover;
  final String? intro;
  final String? author;
  final String? tocUrl;

  const BookInfo({this.cover, this.intro, this.author, this.tocUrl});
}

class TocEntry {
  final String title;
  final String url;

  const TocEntry({required this.title, required this.url});
}
