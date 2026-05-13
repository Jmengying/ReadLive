import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  Future<List<SearchResult>> extractSearchResults(
    String body,
    SearchRule rule,
    String sourceId,
    String sourceName, {
    RuleContext? context,
    String? baseUrl,
  }) async {
    // Skip sources with @js: list rules for HTML parsing — they require Java/jsoup.
    // For JSON responses, the <js> prefix will be stripped in _extractSearchResultsFromJson.
    if (rule.list.startsWith('@js:') && !(body.trim().startsWith('{') || body.trim().startsWith('['))) {
      return [];
    }

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

    // HTML/CSS extraction path — use async version for JS support
    try {
      final tableRules = <String, String>{};
      if (rule.bookName != null) tableRules['bookName'] = rule.bookName!;
      if (rule.author != null) tableRules['author'] = rule.author!;
      if (rule.cover != null) tableRules['cover'] = rule.cover!;
      if (rule.intro != null) tableRules['intro'] = rule.intro!;
      if (rule.bookUrl != null) tableRules['bookUrl'] = rule.bookUrl!;

      final rows = await _parser.extractTableAsync(body, rule.list, tableRules, context: context, baseUrl: baseUrl);

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
    } catch (_) {
      return [];
    }
  }

  /// Extract search results from parsed JSON using JSONPath rules.
  List<SearchResult> _extractSearchResultsFromJson(
    dynamic jsonData,
    SearchRule rule,
    String sourceId,
    String sourceName,
  ) {
    // Clean the list rule: strip <js>...</js> prefix and @json: prefix
    var listRule = rule.list;
    listRule = _stripJsPrefix(listRule);
    if (listRule.startsWith('@json:')) {
      listRule = listRule.substring(6).trim();
    }

    // Try each path separated by ||
    final List<dynamic> items;
    try {
      items = _readJsonPathWithFallback(jsonData, listRule);
    } catch (_) {
      return [];
    }

    final results = <SearchResult>[];
    for (final item in items) {
      if (item is! Map) continue;

      // Use a local context for @put/@get between fields
      final localCtx = <String, String>{};

      final bookName = _extractJsonFieldEnhanced(item, rule.bookName, localCtx);
      final bookUrl = _extractJsonFieldEnhanced(item, rule.bookUrl, localCtx);

      if (bookName.isEmpty || bookUrl.isEmpty) continue;

      results.add(SearchResult(
        bookName: bookName,
        author: _extractJsonFieldEnhanced(item, rule.author, localCtx),
        cover: _extractJsonFieldEnhanced(item, rule.cover, localCtx),
        intro: _extractJsonFieldEnhanced(item, rule.intro, localCtx),
        bookUrl: bookUrl,
        sourceId: sourceId,
        sourceName: sourceName,
      ));
    }
    return results;
  }

  /// Strip `<js>...</js>` prefix from a rule, keeping the part after the closing tag.
  String _stripJsPrefix(String rule) {
    final trimmed = rule.trim();
    if (trimmed.startsWith('<js>')) {
      final endIdx = trimmed.indexOf('</js>');
      if (endIdx >= 0) {
        return trimmed.substring(endIdx + 5).trim();
      }
    }
    return trimmed;
  }

  /// Try JSONPath expressions separated by `||`, returning the first non-empty result.
  /// Also handles `[*]` expansion for arrays returned as single items.
  List<dynamic> _readJsonPathWithFallback(dynamic jsonData, String pathExpr) {
    // Handle || fallback paths
    final paths = pathExpr.split('||').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    for (final path in paths) {
      try {
        final matches = JsonPath(path).read(jsonData);
        if (matches.isEmpty) continue;

        final values = matches.map((m) => m.value).toList();

        // If we got a single item that is a list, expand it
        if (values.length == 1 && values[0] is List) {
          return values[0] as List;
        }

        // Filter out non-map items for search results
        if (values.any((v) => v is Map)) {
          return values;
        }
      } catch (e) {
        debugPrint('ContentExtractor: JSONPath "$path" failed: $e');
        continue;
      }
    }
    return [];
  }

  /// Extract a field value with support for templates, @put/@get, and @js:.
  String _extractJsonFieldEnhanced(
    dynamic item,
    String? rule,
    Map<String, String> localCtx,
  ) {
    if (rule == null || rule.isEmpty) return '';

    // Handle @put:{key:$.path} — extract value and store it
    final putMatch = RegExp(r'^@put:\{(\w+):(.+)\}$').firstMatch(rule.trim());
    if (putMatch != null) {
      final key = putMatch.group(1)!;
      final path = putMatch.group(2)!.trim();
      final value = _readJsonPathFromItem(item, path);
      if (value != null) localCtx[key] = value;
      return value ?? '';
    }

    // Handle @get:key — read from local context
    final getMatch = RegExp(r'^@get:(\w+)$').firstMatch(rule.trim());
    if (getMatch != null) {
      return localCtx[getMatch.group(1)!] ?? '';
    }

    // Handle @js: — skip for now (requires JS engine)
    if (rule.trim().startsWith('@js:')) {
      return '';
    }

    // Handle template expressions like "https://example.com/{{$.id}}"
    // or combined fields like "{{$.author}}  演播：{{$.announcer}}"
    if (rule.contains('{{')) {
      return _resolveJsonTemplate(item, rule, localCtx);
    }

    // Simple JSONPath extraction
    return _readJsonPathFromItem(item, rule) ?? '';
  }

  /// Resolve a template string with {{$.path}} expressions.
  String _resolveJsonTemplate(dynamic item, String template, Map<String, String> localCtx) {
    return template.replaceAllMapped(RegExp(r'\{\{(.+?)\}\}'), (match) {
      final expr = match.group(1)!.trim();

      // Handle @get:key
      if (expr.startsWith('@get:')) {
        return localCtx[expr.substring(5).trim()] ?? '';
      }

      // Handle $.path JSONPath expressions
      if (expr.startsWith(r'$.')) {
        return _readJsonPathFromItem(item, expr) ?? '';
      }

      // Handle Date.parse / Date.now etc.
      if (expr.contains('Date')) {
        return DateTime.now().millisecondsSinceEpoch.toString();
      }

      return match.group(0)!;
    });
  }

  /// Read a JSONPath expression from an item, returning null if not found.
  String? _readJsonPathFromItem(dynamic item, String path) {
    try {
      final matches = JsonPath(path).read(item);
      if (matches.isEmpty) return null;
      final value = matches.first.value;
      return value?.toString();
    } catch (e) {
      debugPrint('ContentExtractor: JSONPath "$path" failed: $e');
      return null;
    }
  }

  /// Extract book info from a book detail page.
  ///
  /// Automatically detects JSON responses and uses JSONPath extraction.
  Future<BookInfo> extractBookInfo(String body, BookInfoRule rule, {RuleContext? context, String? baseUrl}) async {
    // Detect JSON response
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final jsonData = jsonDecode(trimmed);
        return _extractBookInfoFromJson(jsonData, rule);
      } catch (_) {}
    }

    // HTML path
    return BookInfo(
      cover: rule.cover != null ? await _parser.extractTextAsync(body, rule.cover!, context: context, baseUrl: baseUrl) : null,
      intro: rule.intro != null ? await _parser.extractTextAsync(body, rule.intro!, context: context, baseUrl: baseUrl) : null,
      author: rule.author != null ? await _parser.extractTextAsync(body, rule.author!, context: context, baseUrl: baseUrl) : null,
      tocUrl: rule.tocUrl != null
          ? _parser.resolveTemplate(rule.tocUrl!, {}, context: context)
          : null,
    );
  }

  BookInfo _extractBookInfoFromJson(dynamic jsonData, BookInfoRule rule) {
    return BookInfo(
      cover: rule.cover != null ? _readJsonField(jsonData, rule.cover!) : null,
      intro: rule.intro != null ? _readJsonField(jsonData, rule.intro!) : null,
      author: rule.author != null ? _readJsonField(jsonData, rule.author!) : null,
      tocUrl: rule.tocUrl != null ? _readJsonField(jsonData, rule.tocUrl!) : null,
    );
  }

  /// Read a single string field from JSON, normalizing the path.
  String? _readJsonField(dynamic jsonData, String rule) {
    if (rule.isEmpty) return null;
    final path = _normalizeJsonPath(rule);
    return _readJsonPathFromItem(jsonData, path);
  }

  /// Ensure a JSONPath expression starts with `$`.
  String _normalizeJsonPath(String path) {
    var p = path.trim();
    if (p.startsWith('@json:')) p = p.substring(6).trim();
    if (!p.startsWith(r'$')) {
      if (p.startsWith('.')) {
        p = r'$' + p;
      } else {
        p = r'$.' + p;
      }
    }
    return p;
  }

  /// Extract table of contents (chapter list) from HTML or JSON.
  ///
  /// Automatically detects JSON responses and uses JSONPath extraction.
  Future<List<TocEntry>> extractToc(String body, TocRule rule, {RuleContext? context, String? baseUrl}) async {
    // Detect JSON response
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final jsonData = jsonDecode(trimmed);
        return _extractTocFromJson(jsonData, rule);
      } catch (_) {}
    }

    // HTML path
    final names = await _parser.extractListAsync(body, rule.list, rule.name, context: context, baseUrl: baseUrl);
    final urls = await _parser.extractListAsync(body, rule.list, rule.url, context: context, baseUrl: baseUrl);

    final entries = <TocEntry>[];
    final count = names.length < urls.length ? names.length : urls.length;
    for (var i = 0; i < count; i++) {
      entries.add(TocEntry(title: names[i], url: urls[i]));
    }
    return entries;
  }

  List<TocEntry> _extractTocFromJson(dynamic jsonData, TocRule rule) {
    final listPath = _normalizeJsonPath(rule.list);
    final items = _readJsonPathWithFallback(jsonData, listPath);
    if (items.isEmpty) return [];

    final namePath = _normalizeJsonPath(rule.name);
    final urlPath = _normalizeJsonPath(rule.url);

    final entries = <TocEntry>[];
    for (final item in items) {
      if (item is! Map) continue;
      final name = _readJsonPathFromItem(item, namePath) ?? '';
      final url = _readJsonPathFromItem(item, urlPath) ?? '';
      if (name.isNotEmpty && url.isNotEmpty) {
        entries.add(TocEntry(title: name, url: url));
      }
    }
    return entries;
  }

  /// Extract chapter text content from HTML or JSON.
  ///
  /// Automatically detects JSON responses and uses JSONPath extraction.
  Future<String> extractChapterContent(String body, ContentRule rule, {RuleContext? context, String? baseUrl}) async {
    // Detect JSON response
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final jsonData = jsonDecode(trimmed);
        final path = _normalizeJsonPath(rule.content);
        final result = _readJsonPathFromItem(jsonData, path);
        if (result != null && result.isNotEmpty) return result;
      } catch (_) {}
    }

    // HTML path
    return _parser.extractContentAsync(body, rule.content, context: context, baseUrl: baseUrl);
  }

  /// Extract image URLs from a manga chapter page.
  ///
  /// Automatically detects JSON responses and uses JSONPath extraction.
  Future<List<String>> extractImageUrls(String body, String? imagesRule, {String? baseUrl}) async {
    if (imagesRule == null || imagesRule.isEmpty) return [];

    // Detect JSON response
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final jsonData = jsonDecode(trimmed);
        final path = _normalizeJsonPath(imagesRule);
        final matches = _readJsonPathWithFallback(jsonData, path);
        return matches.map((m) => m.toString()).where((s) => s.isNotEmpty).toList();
      } catch (_) {}
    }

    // HTML path
    return _parser.extractListAsync(body, imagesRule, '@src', baseUrl: baseUrl);
  }

  /// Check if there is a next page URL.
  ///
  /// Automatically detects JSON responses and uses JSONPath extraction.
  Future<String?> extractNextPageUrl(String body, String? nextPageRule, {RuleContext? context, String? baseUrl}) async {
    if (nextPageRule == null || nextPageRule.isEmpty) return null;

    // Detect JSON response
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final jsonData = jsonDecode(trimmed);
        final path = _normalizeJsonPath(nextPageRule);
        final result = _readJsonPathFromItem(jsonData, path);
        if (result != null && result.isNotEmpty) return result;
        return null;
      } catch (_) {}
    }

    // HTML path
    return _parser.extractTextAsync(body, nextPageRule, context: context, baseUrl: baseUrl);
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
