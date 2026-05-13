import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:readlive/core/network/url_utils.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/data/html_fetcher.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
import 'package:readlive/features/book_source/data/rule_handlers/js_handler.dart';
import 'package:readlive/features/book_source/data/rule_parser.dart';
import 'package:readlive/features/book_source/domain/book_source_entity.dart';
import 'package:readlive/features/book_source/domain/search_result.dart';

/// Resolved result of parsing a Legado searchUrl template.
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

/// Static utility for parsing Legado searchUrl templates.
///
/// Supports:
/// - GET URLs with `{{key}}` and `{{page}}` template variables
/// - `@post:` prefix for POST requests (form or JSON body)
/// - `@Header:` prefix for custom headers
/// - `@js:` prefix for JavaScript-evaluated URLs
/// - Relative URL resolution against a host
class SearchUrlResolver {
  /// Shared JS handler for @js: searchUrl evaluation.
  static final _jsHandler = JsHandler();

  /// Parse a Legado searchUrl template into a [ResolvedSearchUrl].
  ///
  /// [searchUrlTemplate] — the raw searchUrl from the source rule
  /// [keyword] — the search keyword to substitute for `{{key}}`
  /// [host] — the source host for resolving relative URLs
  static Future<ResolvedSearchUrl> resolve(
    String searchUrlTemplate,
    String keyword,
    String host, {
    RuleContext? context,
    RuleParser? parser,
  }) async {
    var template = searchUrlTemplate;
    Map<String, String>? headers;
    var isPost = false;

    // 1. Handle @js: prefix — execute JS to get the URL
    if (template.startsWith('@js:')) {
      return _resolveJs(template, keyword, host, context: context);
    }

    // 2. Extract @Header: prefix if present
    if (template.startsWith('@Header:')) {
      final headerEnd = template.indexOf('\n');
      if (headerEnd >= 0) {
        final headerStr = template.substring(8, headerEnd);
        headers = parseHeaderString(headerStr);
        template = template.substring(headerEnd + 1);
      } else {
        final headerStr = template.substring(8);
        headers = parseHeaderString(headerStr);
        template = '';
      }
    }

    // 3. Handle @post: prefix
    String? body;
    if (template.startsWith('@post:')) {
      isPost = true;
      final content = template.substring(6);
      final commaIdx = content.indexOf(',');
      if (commaIdx >= 0) {
        template = content.substring(0, commaIdx);
        body = content.substring(commaIdx + 1);
      } else {
        template = content;
      }
    }

    // 4. Resolve template variables
    final effectiveParser = parser ?? RuleParser();
    final variables = {'key': keyword, 'page': '1'};
    template = effectiveParser.resolveTemplate(template, variables, context: context);
    if (body != null) {
      body = effectiveParser.resolveTemplate(body, variables, context: context);
    }

    // 5. Resolve relative URL
    template = resolveUrl(host, template);

    return ResolvedSearchUrl(
      url: template,
      isPost: isPost,
      body: body,
      headers: headers,
    );
  }

  /// Handle @js: searchUrl — execute JavaScript and parse the result.
  ///
  /// The JS code has access to:
  /// - `key` (search keyword), `page` (page number), `host` (source host)
  /// - `java.put(k, v)`, `java.get(k)`, `java.encodeURI(s)`, `java.md5Encode(s)`
  ///
  /// The JS result can be:
  /// - A plain URL string: `"/api/search?q=xxx"`
  /// - A URL with comma-separated headers JSON: `"/api/search,{"headers":{...}}"`
  static Future<ResolvedSearchUrl> _resolveJs(
    String template,
    String keyword,
    String host, {
    RuleContext? context,
  }) async {
    final effectiveContext = context ?? RuleContext();
    // Pre-set key and page so java.get('key') works in JS
    effectiveContext.put('key', keyword);
    effectiveContext.put('page', '1');
    effectiveContext.put('host', host);

    final result = await _jsHandler.execute(template, effectiveContext);

    if (result == null || result.isEmpty) {
      return const ResolvedSearchUrl(url: '', isPost: false);
    }

    // Parse the result — may contain URL + comma-separated headers JSON
    var url = result;
    Map<String, String>? headers;

    // Check for headers set via java.put('headers', ...)
    final ctxHeaders = effectiveContext.get('headers');
    if (ctxHeaders.isNotEmpty) {
      try {
        final parsed = jsonDecode(ctxHeaders);
        if (parsed is Map) {
          headers = parsed.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    // Also check for comma-separated headers in the result itself
    // Pattern: "/api/path,{"headers":{"key":"value"}}"
    if (headers == null) {
      final lastComma = result.lastIndexOf(',{');
      if (lastComma > 0) {
        final maybeJson = result.substring(lastComma + 1);
        if (maybeJson.startsWith('{')) {
          try {
            final parsed = jsonDecode(maybeJson);
            if (parsed is Map && parsed.containsKey('headers')) {
              url = result.substring(0, lastComma);
              final h = parsed['headers'];
              if (h is Map) {
                headers = h.map((k, v) => MapEntry(k.toString(), v.toString()));
              }
            }
          } catch (_) {}
        }
      }
    }

    // Resolve relative URL
    url = resolveUrl(host, url);

    return ResolvedSearchUrl(
      url: url,
      isPost: false,
      headers: headers,
    );
  }

  /// Parse a header string in Legado format.
  /// Supports both `key=value\nkey2=value2` (newline-delimited, Legado standard)
  /// and `key=value&key2=value2` (ampersand-delimited) formats.
  /// Also handles literal `\n` (backslash+n) from JSON strings.
  static Map<String, String> parseHeaderString(String headerStr) {
    final headers = <String, String>{};
    // Normalize: replace literal \n (two chars) with actual newline
    var normalized = headerStr.replaceAll('\\n', '\n');
    // Split by actual newline or ampersand
    final lines = normalized.split(RegExp(r'[\n&]'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx >= 0) {
        headers[trimmed.substring(0, eqIdx).trim()] =
            trimmed.substring(eqIdx + 1).trim();
      }
    }
    return headers;
  }
}

/// Service for searching a single book source.
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

  /// Search a single book source for [keyword].
  Future<List<SearchResult>> searchSource({
    required BookSourceEntity source,
    required String keyword,
    RuleContext? context,
    CancelToken? cancelToken,
  }) async {
    final rule = source.parseRule();
    final searchRule = rule.search;
    if (searchRule == null) return [];

    // Resolve the search URL template
    final resolved = await SearchUrlResolver.resolve(
      searchRule.url,
      keyword,
      source.host,
      context: context,
      parser: _parser,
    );

    // Merge headers from @Header: prefix and SearchRule.headers field
    final headers = <String, String>{};
    if (resolved.headers != null) headers.addAll(resolved.headers!);
    if (searchRule.headers != null) {
      headers.addAll(SearchUrlResolver.parseHeaderString(searchRule.headers!));
    }

    // Make HTTP request
    final String body;
    if (resolved.isPost) {
      body = await _fetcher.post(
        resolved.url,
        data: resolved.body,
        headers: headers.isEmpty ? null : headers,
        cancelToken: cancelToken,
      );
    } else {
      body = await _fetcher.fetch(
        resolved.url,
        headers: headers.isEmpty ? null : headers,
        cancelToken: cancelToken,
      );
    }

    // Extract search results
    return _extractor.extractSearchResults(
      body,
      searchRule,
      source.id,
      source.name,
      context: context,
      baseUrl: source.host,
    );
  }
}
