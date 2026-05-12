# Legado 搜索功能完整重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the online search to fully match Legado's search flow — correct URL parsing, parallel source queries, per-source grouped results UI, and cancellation support.

**Architecture:** New `SearchService` encapsulates per-source search logic (URL parsing, HTTP request, result extraction). `SearchNotifier` is rewritten to use it with per-source state tracking. `SearchPage` gets a grouped-by-source UI. `SwitchSourceSheet` is refactored to reuse `SearchService`.

**Tech Stack:** Flutter, Riverpod, Dio (CancelToken), existing RuleParser/ContentExtractor/HtmlFetcher

---

## File Structure

```
Create:
  lib/features/book_source/data/search_service.dart         # Per-source search logic + URL parsing

Modify:
  lib/features/book_source/data/rule_parser.dart            # URL-encode {{key}} in resolveTemplate
  lib/features/book_source/domain/source_rule.dart          # Add headers field to SearchRule
  lib/features/book_source/data/content_extractor.dart      # JSON search result support
  lib/features/book_source/presentation/book_source_provider.dart  # Rewrite SearchNotifier + add SearchService provider
  lib/features/book_source/presentation/search_page.dart    # Grouped-by-source UI
  lib/features/book_source/presentation/switch_source_sheet.dart   # Use SearchService

Test:
  test/features/book_source/data/rule_parser_test.dart      # Add URL-encoding tests
  test/features/book_source/data/search_service_test.dart   # New: SearchService unit tests
  test/features/book_source/data/content_extractor_test.dart # Add JSON extraction tests
```

---

### Task 1: Fix {{key}} URL encoding in RuleParser

**Files:**
- Modify: `lib/features/book_source/data/rule_parser.dart:56-58`
- Modify: `test/features/book_source/data/rule_parser_test.dart`

- [ ] **Step 1: Write failing test for URL encoding**

Add to `test/features/book_source/data/rule_parser_test.dart` inside the `resolveTemplate` group:

```dart
test('URL-encodes {{key}} variable', () {
  final result = parser.resolveTemplate(
    'https://example.com/search?q={{key}}',
    {'key': '斗破苍穹'},
  );
  expect(result, 'https://example.com/search?q=%E6%96%97%E7%A0%B4%E8%8B%8D%E7%A9%B9');
});

test('URL-encodes key with spaces and special chars', () {
  final result = parser.resolveTemplate(
    'https://example.com/search?q={{key}}',
    {'key': 'hello world & more'},
  );
  expect(result, 'https://example.com/search?q=hello%20world%20%26%20more');
});

test('does not double-encode java.encodeURI(key)', () {
  final result = parser.resolveTemplate(
    'https://example.com/search?q={{java.encodeURI(key)}}',
    {'key': 'test'},
  );
  expect(result, 'https://example.com/search?q=test');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/book_source/data/rule_parser_test.dart`
Expected: FAIL — `{{key}}` is replaced with raw `斗破苍穹` instead of encoded form.

- [ ] **Step 3: Implement URL encoding in resolveTemplate**

In `lib/features/book_source/data/rule_parser.dart`, replace lines 56-58 (the simple variable substitution loop):

```dart
    // Handle simple variable substitution
    for (final entry in variables.entries) {
      var value = entry.value;
      // key variable is auto URL-encoded (search keywords must be encoded in URLs)
      if (entry.key == 'key') {
        value = Uri.encodeComponent(value);
      }
      result = result.replaceAll('{{${entry.key}}}', value);
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/book_source/data/rule_parser_test.dart`
Expected: All tests PASS (including the new URL-encoding tests and all existing tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/book_source/data/rule_parser.dart test/features/book_source/data/rule_parser_test.dart
git commit -m "fix: URL-encode {{key}} variable in resolveTemplate for search keywords"
```

---

### Task 2: Add headers field to SearchRule

**Files:**
- Modify: `lib/features/book_source/domain/source_rule.dart:146-192`
- Modify: `lib/features/book_source/domain/source_rule.dart:59-126` (Legado conversion)

- [ ] **Step 1: Add headers field to SearchRule class**

In `lib/features/book_source/domain/source_rule.dart`, update the `SearchRule` class:

```dart
class SearchRule {
  final String url;
  final String list;
  final String? bookName;
  final String? author;
  final String? cover;
  final String? intro;
  final String? bookUrl;
  final String? nextPage;
  final String? headers;

  const SearchRule({
    required this.url,
    required this.list,
    this.bookName,
    this.author,
    this.cover,
    this.intro,
    this.bookUrl,
    this.nextPage,
    this.headers,
  });

  factory SearchRule.fromJson(Map<String, dynamic> json) {
    return SearchRule(
      url: json['url'] as String? ?? '',
      list: json['list'] as String? ?? '',
      bookName: json['bookName'] as String?,
      author: json['author'] as String?,
      cover: json['cover'] as String?,
      intro: json['intro'] as String?,
      bookUrl: json['bookUrl'] as String?,
      nextPage: json['nextPage'] as String?,
      headers: json['headers'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'list': list,
      if (bookName != null) 'bookName': bookName,
      if (author != null) 'author': author,
      if (cover != null) 'cover': cover,
      if (intro != null) 'intro': intro,
      if (bookUrl != null) 'bookUrl': bookUrl,
      if (nextPage != null) 'nextPage': nextPage,
      if (headers != null) 'headers': headers,
    };
  }
}
```

- [ ] **Step 2: Update Legado conversion to include header**

In `source_rule.dart`, in `_convertLegado()`, update the search map to include the header field:

```dart
    if (ruleSearch != null || searchUrl != null) {
      search = {
        if (searchUrl != null) 'url': searchUrl,
        if (ruleSearch?['bookList'] != null) 'list': ruleSearch!['bookList'],
        if (ruleSearch?['name'] != null) 'bookName': ruleSearch!['name'],
        if (ruleSearch?['author'] != null) 'author': ruleSearch!['author'],
        if (ruleSearch?['coverUrl'] != null) 'cover': ruleSearch!['coverUrl'],
        if (ruleSearch?['intro'] != null) 'intro': ruleSearch!['intro'],
        if (ruleSearch?['bookUrl'] != null) 'bookUrl': ruleSearch!['bookUrl'],
        if (ruleSearch?['nextPageUrl'] != null) 'nextPage': ruleSearch!['nextPageUrl'],
        if (ruleSearch?['header'] != null) 'headers': ruleSearch!['header'],
      };
    }
```

- [ ] **Step 3: Run existing source_rule tests**

Run: `flutter test test/features/book_source/domain/source_rule_test.dart`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/book_source/domain/source_rule.dart
git commit -m "feat: add headers field to SearchRule for source-level custom headers"
```

---

### Task 3: Add JSON search result support to ContentExtractor

**Files:**
- Modify: `lib/features/book_source/data/content_extractor.dart`
- Modify: `test/features/book_source/data/content_extractor_test.dart`

- [ ] **Step 1: Write failing test for JSON search results**

Add to `test/features/book_source/data/content_extractor_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/book_source/data/content_extractor_test.dart`
Expected: FAIL — JSON body is parsed as HTML, no results extracted.

- [ ] **Step 3: Implement JSON detection in extractSearchResults**

In `lib/features/book_source/data/content_extractor.dart`, update `extractSearchResults`:

```dart
  /// Extract search results from HTML or JSON.
  List<SearchResult> extractSearchResults(
    String body,
    SearchRule rule,
    String sourceId,
    String sourceName, {
    RuleContext? context,
  }) {
    // Detect JSON response
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final jsonData = jsonDecode(trimmed);
        return _extractSearchResultsFromJson(
          jsonData, rule, sourceId, sourceName, context: context,
        );
      } catch (_) {
        // JSON parse failed, fall through to HTML parsing
      }
    }

    // HTML parsing (existing logic)
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

  List<SearchResult> _extractSearchResultsFromJson(
    dynamic jsonData,
    SearchRule rule,
    String sourceId,
    String sourceName, {
    RuleContext? context,
  }) {
    // Use list rule as JSONPath to get the array of items
    final items = _parser.extractListFromJson(jsonData, rule.list, context: context);

    // If list extraction returns strings (not objects), try to extract from each item
    if (jsonData is Map) {
      final listData = _jsonpathHandler.extractList(jsonData, rule.list.startsWith('@json:') ? rule.list.substring(6) : rule.list);
      if (listData.isEmpty) return [];

      final results = <SearchResult>[];
      // Try to read the list as objects
      final rawList = JsonPath(rule.list.startsWith('@json:') ? rule.list.substring(6) : rule.list).read(jsonData);
      for (final match in rawList) {
        final item = match.value;
        if (item is! Map) continue;

        final bookName = _extractJsonField(item, rule.bookName);
        final bookUrl = _extractJsonField(item, rule.bookUrl);
        if (bookName == null || bookName.isEmpty || bookUrl == null || bookUrl.isEmpty) continue;

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

    return [];
  }

  String? _extractJsonField(dynamic item, String? rule) {
    if (rule == null || rule.isEmpty || item is! Map) return null;
    final cleanRule = rule.startsWith('@json:') ? rule.substring(6) : rule;
    return _jsonpathHandler.extractText(item, cleanRule);
  }
```

Make sure to add the `dart:convert` import at the top:

```dart
import 'dart:convert';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/book_source/data/content_extractor_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/book_source/data/content_extractor.dart test/features/book_source/data/content_extractor_test.dart
git commit -m "feat: support JSON API responses in search result extraction"
```

---

### Task 4: Create SearchService

**Files:**
- Create: `lib/features/book_source/data/search_service.dart`
- Create: `test/features/book_source/data/search_service_test.dart`

- [ ] **Step 1: Write failing tests for SearchService URL parsing**

Create `test/features/book_source/data/search_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/search_service.dart';

void main() {
  group('SearchUrlResolver', () {
    test('resolves GET URL with key encoding', () {
      final result = SearchUrlResolver.resolve(
        'https://example.com/search?q={{key}}&page={{page}}',
        '斗破苍穹',
        'https://example.com',
      );
      expect(result.isPost, false);
      expect(result.url, contains('q=%E6%96%97%E7%A0%B4'));
      expect(result.url, contains('page=1'));
      expect(result.body, isNull);
    });

    test('resolves POST form body', () {
      final result = SearchUrlResolver.resolve(
        r'@post:https://example.com/search,key={{key}}&page={{page}}',
        'test',
        'https://example.com',
      );
      expect(result.isPost, true);
      expect(result.url, 'https://example.com/search');
      expect(result.body, contains('key='));
      expect(result.body, contains('page=1'));
    });

    test('resolves POST JSON body', () {
      final result = SearchUrlResolver.resolve(
        r'@post:https://example.com/api/search,{"q":"{{key}}","page":1}',
        'test',
        'https://example.com',
      );
      expect(result.isPost, true);
      expect(result.url, 'https://example.com/api/search');
      expect(result.body, contains('"q"'));
    });

    test('resolves @Header with URL', () {
      final result = SearchUrlResolver.resolve(
        '@Header:Cookie=abc123\nhttps://example.com/search?q={{key}}',
        'test',
        'https://example.com',
      );
      expect(result.headers, isNotNull);
      expect(result.headers!['Cookie'], 'abc123');
      expect(result.url, contains('example.com/search'));
    });

    test('resolves relative URL against host', () {
      final result = SearchUrlResolver.resolve(
        '/search?q={{key}}',
        'test',
        'https://example.com',
      );
      expect(result.url, 'https://example.com/search?q=test');
    });

    test('resolves @post: with body containing commas', () {
      final result = SearchUrlResolver.resolve(
        r'@post:https://example.com/api,a=1,b=2,c={{key}}',
        'test',
        'https://example.com',
      );
      expect(result.isPost, true);
      expect(result.url, 'https://example.com/api');
      expect(result.body, 'a=1,b=2,c=test');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/book_source/data/search_service_test.dart`
Expected: FAIL — `SearchUrlResolver` class doesn't exist.

- [ ] **Step 3: Implement SearchService**

Create `lib/features/book_source/data/search_service.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:readlive/core/network/url_utils.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/data/html_fetcher.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
import 'package:readlive/features/book_source/data/rule_parser.dart';
import 'package:readlive/features/book_source/domain/book_source_entity.dart';
import 'package:readlive/features/book_source/domain/search_result.dart';

class ResolvedSearchUrl {
  final String url;
  final bool isPost;
  final String? body;
  final Map<String, String>? headers;

  const ResolvedSearchUrl({
    required this.url,
    required this.isPost,
    this.body,
    this.headers,
  });
}

class SearchUrlResolver {
  /// Parse a Legado searchUrl template into a resolved URL with method, body, and headers.
  static ResolvedSearchUrl resolve(
    String searchUrlTemplate,
    String keyword,
    String host, {
    RuleContext? context,
    RuleParser? parser,
  }) {
    final ruleParser = parser ?? RuleParser();
    var url = searchUrlTemplate;
    Map<String, String>? headers;
    bool isPost = false;
    String? body;

    // 1. Extract @Header: prefix
    if (url.startsWith('@Header:')) {
      final headerEnd = url.indexOf('\n');
      if (headerEnd > 0) {
        final headerStr = url.substring(8, headerEnd);
        headers = _parseHeaderString(headerStr);
        url = url.substring(headerEnd + 1).trim();
      }
    }

    // 2. Detect @post: prefix
    if (url.startsWith('@post:')) {
      isPost = true;
      url = url.substring(6);
      // Separate URL and body at first comma
      final commaIdx = url.indexOf(',');
      if (commaIdx > 0) {
        body = url.substring(commaIdx + 1).trim();
        url = url.substring(0, commaIdx).trim();
      }
    }

    // 3. Template variable substitution (URL and body)
    final variables = {'key': keyword, 'page': '1'};
    url = ruleParser.resolveTemplate(url, variables, context: context);
    if (body != null) {
      body = ruleParser.resolveTemplate(body, variables, context: context);
    }

    // 4. Resolve relative URL
    url = resolveUrl(host, url);

    return ResolvedSearchUrl(
      url: url,
      isPost: isPost,
      body: body,
      headers: headers,
    );
  }

  /// Parse header string format: key=value&key2=value2
  static Map<String, String> _parseHeaderString(String headerStr) {
    final headers = <String, String>{};
    for (final pair in headerStr.split('&')) {
      final eqIdx = pair.indexOf('=');
      if (eqIdx > 0) {
        headers[pair.substring(0, eqIdx).trim()] = pair.substring(eqIdx + 1).trim();
      }
    }
    return headers;
  }
}

class SearchService {
  final HtmlFetcher _fetcher;
  final ContentExtractor _extractor;
  final RuleParser _parser;

  SearchService({
    HtmlFetcher? fetcher,
    ContentExtractor? extractor,
    RuleParser? parser,
  })  : _fetcher = fetcher ?? HtmlFetcher(),
        _extractor = extractor ?? ContentExtractor(),
        _parser = parser ?? RuleParser();

  /// Search a single book source. Returns results list.
  /// Supports cancellation via CancelToken.
  Future<List<SearchResult>> searchSource({
    required BookSourceEntity source,
    required String keyword,
    RuleContext? context,
    CancelToken? cancelToken,
  }) async {
    final rule = source.parseRule();
    if (rule.search == null) return [];

    final ctx = context ?? RuleContext();

    // 1. Parse search URL template
    final resolved = SearchUrlResolver.resolve(
      rule.search!.url,
      keyword,
      source.host,
      context: ctx,
      parser: _parser,
    );

    // 2. Merge headers: source-level + SearchRule headers
    final mergedHeaders = <String, String>{};
    if (resolved.headers != null) {
      mergedHeaders.addAll(resolved.headers!);
    }
    if (rule.search!.headers != null && rule.search!.headers!.isNotEmpty) {
      mergedHeaders.addAll(SearchUrlResolver._parseHeaderString(rule.search!.headers!));
    }

    // 3. Send request
    final String responseBody;
    if (resolved.isPost) {
      responseBody = await _fetcher.post(
        resolved.url,
        data: resolved.body,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        cancelToken: cancelToken,
      );
    } else {
      responseBody = await _fetcher.fetch(
        resolved.url,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        cancelToken: cancelToken,
      );
    }

    // 4. Extract results
    return _extractor.extractSearchResults(
      responseBody,
      rule.search!,
      source.id,
      source.name,
      context: ctx,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/book_source/data/search_service_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/book_source/data/search_service.dart test/features/book_source/data/search_service_test.dart
git commit -m "feat: add SearchService with Legado URL parsing and per-source search"
```

---

### Task 5: Add SearchService provider to book_source_provider.dart

**Files:**
- Modify: `lib/features/book_source/presentation/book_source_provider.dart`

- [ ] **Step 1: Add SearchService provider**

At the top of `book_source_provider.dart`, add the import:

```dart
import 'package:readlive/features/book_source/data/search_service.dart';
```

Add the provider after the existing infrastructure providers:

```dart
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(
    fetcher: ref.watch(htmlFetcherProvider),
    extractor: ref.watch(contentExtractorProvider),
    parser: ref.watch(ruleParserProvider),
  );
});
```

- [ ] **Step 2: Run existing tests to verify no regression**

Run: `flutter test test/features/book_source/`
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/features/book_source/presentation/book_source_provider.dart
git commit -m "feat: add searchServiceProvider to Riverpod providers"
```

---

### Task 6: Rewrite SearchNotifier with per-source state

**Files:**
- Modify: `lib/features/book_source/presentation/book_source_provider.dart:54-161`

- [ ] **Step 1: Rewrite SearchState and SearchNotifier**

Replace the entire `SearchState`, `SearchNotifier`, and `searchProvider` in `book_source_provider.dart`:

```dart
// Per-source search state
class SourceSearchState {
  final String sourceId;
  final String sourceName;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;

  const SourceSearchState({
    required this.sourceId,
    required this.sourceName,
    this.results = const [],
    this.isLoading = true,
    this.error,
  });

  SourceSearchState copyWith({
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return SourceSearchState(
      sourceId: sourceId,
      sourceName: sourceName,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Overall search state
class SearchState {
  final String query;
  final List<SourceSearchState> sourceStates;
  final bool isLoading;

  const SearchState({
    this.query = '',
    this.sourceStates = const [],
    this.isLoading = false,
  });

  /// All results flattened (for backward compatibility)
  List<SearchResult> get results =>
      sourceStates.expand((s) => s.results).toList();

  /// Number of sources still loading
  int get loadingCount =>
      sourceStates.where((s) => s.isLoading).length;

  /// Number of completed sources
  int get completedCount =>
      sourceStates.where((s) => !s.isLoading).length;

  /// Total number of results
  int get totalResultCount =>
      sourceStates.fold(0, (sum, s) => sum + s.results.length);
}

class SearchNotifier extends StateNotifier<SearchState> {
  final BookSourceRepository _repo;
  final SearchService _service;
  CancelToken? _cancelToken;

  SearchNotifier(this._repo, this._service) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    // Cancel previous search
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final cancelToken = _cancelToken!;

    final sources = await _repo.getEnabledSources();

    // Initialize state with all sources in loading
    state = SearchState(
      query: query,
      isLoading: true,
      sourceStates: sources
          .where((s) => s.parseRule().search != null)
          .map((s) => SourceSearchState(
                sourceId: s.id,
                sourceName: s.name,
              ))
          .toList(),
    );

    // Search all sources in parallel
    final sourcesWithSearch = sources.where((s) => s.parseRule().search != null).toList();
    final futures = sourcesWithSearch.map((source) =>
        _searchOneSource(source, query, cancelToken));

    await Future.wait(futures, eagerError: false);

    // Final update: mark loading as done
    if (!cancelToken.isCancelled) {
      state = SearchState(
        query: state.query,
        sourceStates: state.sourceStates,
        isLoading: false,
      );
    }
  }

  Future<void> _searchOneSource(
    BookSourceEntity source,
    String keyword,
    CancelToken cancelToken,
  ) async {
    try {
      final context = RuleContext();
      final results = await _service.searchSource(
        source: source,
        keyword: keyword,
        context: context,
        cancelToken: cancelToken,
      );

      _updateSourceState(source.id, (s) => s.copyWith(
        results: results,
        isLoading: false,
      ));
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      _updateSourceState(source.id, (s) => s.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _updateSourceState(
    String sourceId,
    SourceSearchState Function(SourceSearchState) updater,
  ) {
    final updated = state.sourceStates.map((s) {
      if (s.sourceId == sourceId) return updater(s);
      return s;
    }).toList();

    state = SearchState(
      query: state.query,
      sourceStates: updated,
      isLoading: state.isLoading,
    );
  }

  void cancel() {
    _cancelToken?.cancel();
    state = SearchState(
      query: state.query,
      sourceStates: state.sourceStates.map((s) =>
          s.isLoading
              ? s.copyWith(isLoading: false, error: '已取消')
              : s).toList(),
      isLoading: false,
    );
  }

  void clear() {
    _cancelToken?.cancel();
    state = const SearchState();
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(
    ref.watch(bookSourceRepositoryProvider),
    ref.watch(searchServiceProvider),
  );
});
```

Make sure to add the Dio import at the top:

```dart
import 'package:dio/dio.dart';
import 'package:readlive/features/book_source/data/search_service.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
```

- [ ] **Step 2: Run existing tests to verify no regression**

Run: `flutter test test/features/book_source/`
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/features/book_source/presentation/book_source_provider.dart
git commit -m "feat: rewrite SearchNotifier with per-source state, parallel search, and cancel"
```

---

### Task 7: Rewrite SearchPage with grouped-by-source UI

**Files:**
- Modify: `lib/features/book_source/presentation/search_page.dart`

- [ ] **Step 1: Rewrite SearchPage**

Replace the entire content of `lib/features/book_source/presentation/search_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/book_source/presentation/book_source_provider.dart';
import 'package:readlive/features/book_source/domain/search_result.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索书名...',
            border: InputBorder.none,
          ),
          onSubmitted: (query) {
            ref.read(searchProvider.notifier).search(query);
          },
        ),
        actions: [
          if (searchState.isLoading)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '取消搜索',
              onPressed: () {
                ref.read(searchProvider.notifier).cancel();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                ref.read(searchProvider.notifier).search(_controller.text);
              },
            ),
        ],
      ),
      body: _buildBody(searchState),
    );
  }

  Widget _buildBody(SearchState searchState) {
    if (searchState.query.isEmpty) {
      return const Center(child: Text('输入书名搜索'));
    }

    if (searchState.sourceStates.isEmpty && searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.sourceStates.isEmpty) {
      return const Center(child: Text('没有可用的书源'));
    }

    return Column(
      children: [
        // Status bar
        if (searchState.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  '搜索中 ${searchState.completedCount}/${searchState.sourceStates.length} 个源，'
                  '已找到 ${searchState.totalResultCount} 条结果',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        if (!searchState.isLoading && searchState.totalResultCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '共 ${searchState.totalResultCount} 条结果，'
                '来自 ${searchState.sourceStates.where((s) => s.results.isNotEmpty).length} 个源',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        const Divider(height: 1),
        // Grouped results
        Expanded(
          child: ListView.builder(
            itemCount: searchState.sourceStates.length,
            itemBuilder: (context, index) {
              final sourceState = searchState.sourceStates[index];
              return _SourceGroupTile(
                sourceState: sourceState,
                onBookTap: (result) {
                  context.push(
                    '/book-detail?bookUrl=${Uri.encodeComponent(result.bookUrl)}'
                    '&sourceId=${result.sourceId}'
                    '&bookName=${Uri.encodeComponent(result.bookName)}',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SourceGroupTile extends StatefulWidget {
  final SourceSearchState sourceState;
  final ValueChanged<SearchResult> onBookTap;

  const _SourceGroupTile({
    required this.sourceState,
    required this.onBookTap,
  });

  @override
  State<_SourceGroupTile> createState() => _SourceGroupTileState();
}

class _SourceGroupTileState extends State<_SourceGroupTile> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    // Auto-collapse sources with no results and not loading
    if (!widget.sourceState.isLoading &&
        widget.sourceState.results.isEmpty) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = widget.sourceState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Source header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    source.sourceName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusChip(theme),
              ],
            ),
          ),
        ),
        // Source results
        if (_expanded) ...[
          if (source.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('搜索中...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else if (source.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text(
                source.error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            )
          else if (source.results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text('无结果', style: TextStyle(color: Colors.grey)),
            )
          else
            ...source.results.map((result) => _SearchResultTile(
                  result: result,
                  onTap: () => widget.onBookTap(result),
                )),
        ],
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    final source = widget.sourceState;
    if (source.isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (source.error != null) {
      return Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error);
    }
    if (source.results.isEmpty) {
      return Text('0', style: TextStyle(color: theme.colorScheme.outline, fontSize: 12));
    }
    return Text(
      '${source.results.length}',
      style: TextStyle(
        color: theme.colorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _SearchResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
      leading: Container(
        width: 40,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            result.bookName.substring(0, result.bookName.length.clamp(0, 2)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
      title: Text(result.bookName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        result.author ?? '未知作者',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: Run build to verify compilation**

Run: `flutter analyze lib/features/book_source/presentation/search_page.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/book_source/presentation/search_page.dart
git commit -m "feat: rewrite SearchPage with grouped-by-source UI and cancel support"
```

---

### Task 8: Update SwitchSourceSheet to use SearchService

**Files:**
- Modify: `lib/features/book_source/presentation/switch_source_sheet.dart:37-83`

- [ ] **Step 1: Rewrite _search method**

In `switch_source_sheet.dart`, add the Dio import at the top (for `CancelToken`):

```dart
import 'package:dio/dio.dart';
```

Replace the `_search` method:

```dart
  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(bookSourceRepositoryProvider);
      final sources = await repo.getEnabledSources();
      final service = ref.read(searchServiceProvider);

      final allResults = <SearchResult>[];
      _cancelToken = CancelToken();

      // Search sources in parallel (excluding current source)
      final sourcesToSearch = sources
          .where((s) => s.id != widget.currentSourceId && s.parseRule().search != null)
          .toList();

      final futures = sourcesToSearch.map((source) async {
        try {
          final results = await service.searchSource(
            source: source,
            keyword: widget.bookTitle,
            cancelToken: _cancelToken,
          );
          // Filter to results that roughly match the book title
          final matching = results.where((r) =>
              r.bookName.contains(widget.bookTitle) ||
              widget.bookTitle.contains(r.bookName));
          return matching.isNotEmpty ? matching.toList() : results.take(1).toList();
        } catch (_) {
          return <SearchResult>[];
        }
      });

      final resultLists = await Future.wait(futures);
      for (final list in resultLists) {
        allResults.addAll(list);
      }

      if (mounted) {
        setState(() {
          _results = allResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '搜索失败: $e';
          _isLoading = false;
        });
      }
    }
  }
```

Add a `CancelToken` field to the state class:

```dart
class _SwitchSourceSheetState extends ConsumerState<SwitchSourceSheet> {
  List<SearchResult> _results = [];
  bool _isLoading = true;
  String? _error;
  bool _isSwitching = false;
  CancelToken? _cancelToken;
```

Update `dispose` to cancel:

```dart
  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
```

- [ ] **Step 2: Run build to verify compilation**

Run: `flutter analyze lib/features/book_source/presentation/switch_source_sheet.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/book_source/presentation/switch_source_sheet.dart
git commit -m "refactor: SwitchSourceSheet uses SearchService for parallel search"
```

---

### Task 9: Run full test suite and verify

**Files:** None (verification only)

- [ ] **Step 1: Run all book_source tests**

Run: `flutter test test/features/book_source/`
Expected: All tests PASS.

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`
Expected: No errors (warnings acceptable).

- [ ] **Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: address analysis warnings in search overhaul"
```
