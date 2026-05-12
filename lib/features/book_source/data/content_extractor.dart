import 'dart:convert';
import 'package:json_path/json_path.dart';
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
  ///
  /// Automatically detects JSON responses (body starting with `{` or `[`)
  /// and uses JSONPath extraction. Falls back to HTML/CSS parsing otherwise.
  List<SearchResult> extractSearchResults(
    String body,
    SearchRule rule,
    String sourceId,
    String sourceName, {
    RuleContext? context,
  }) {
    // Try JSON detection first
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final jsonData = jsonDecode(trimmed);
        return _extractSearchResultsFromJson(jsonData, rule, sourceId, sourceName);
      } catch (_) {
        // Not valid JSON, fall through to HTML parsing
      }
    }

    // HTML/CSS extraction path
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

  /// Extract search results from parsed JSON using JSONPath rules.
  List<SearchResult> _extractSearchResultsFromJson(
    dynamic jsonData,
    SearchRule rule,
    String sourceId,
    String sourceName,
  ) {
    // Strip @json: prefix from list rule if present
    final listPath = rule.list.startsWith('@json:')
        ? rule.list.substring(6).trim()
        : rule.list;

    // Get the array of items using JSONPath
    final List<dynamic> items;
    try {
      final matches = JsonPath(listPath).read(jsonData);
      items = matches.map((m) => m.value).toList();
    } catch (_) {
      return [];
    }

    final results = <SearchResult>[];
    for (final item in items) {
      if (item is! Map) continue;

      final bookName = _extractJsonField(item, rule.bookName);
      final bookUrl = _extractJsonField(item, rule.bookUrl);

      if (bookName.isEmpty || bookUrl.isEmpty) continue;

      results.add(SearchResult(
        bookName: bookName,
        author: _extractJsonField(item, rule.author),
        cover: _extractJsonField(item, rule.cover),
        intro: _extractJsonField(item, rule.intro),
        bookUrl: bookUrl,
        sourceId: sourceId,
        sourceName: sourceName,
      ));
    }
    return results;
  }

  /// Extract a single field value from a JSON object using a JSONPath rule.
  String _extractJsonField(dynamic item, String? rule) {
    if (rule == null || rule.isEmpty) return '';
    final path = rule.startsWith('@json:')
        ? rule.substring(6).trim()
        : rule;
    try {
      final matches = JsonPath(path).read(item);
      if (matches.isEmpty) return '';
      final value = matches.first.value;
      return value?.toString() ?? '';
    } catch (_) {
      return '';
    }
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
