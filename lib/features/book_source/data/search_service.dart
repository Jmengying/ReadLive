import 'package:dio/dio.dart';
import 'package:readlive/core/network/url_utils.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/data/html_fetcher.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
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
/// - Relative URL resolution against a host
class SearchUrlResolver {
  /// Parse a Legado searchUrl template into a [ResolvedSearchUrl].
  ///
  /// [searchUrlTemplate] — the raw searchUrl from the source rule
  /// [keyword] — the search keyword to substitute for `{{key}}`
  /// [host] — the source host for resolving relative URLs
  static ResolvedSearchUrl resolve(
    String searchUrlTemplate,
    String keyword,
    String host, {
    RuleContext? context,
    RuleParser? parser,
  }) {
    var template = searchUrlTemplate;
    Map<String, String>? headers;
    var isPost = false;

    // 1. Extract @Header: prefix if present
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

    // 2. Handle @post: prefix
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

    // 3. Resolve template variables
    final effectiveParser = parser ?? RuleParser();
    final variables = {'key': keyword, 'page': '1'};
    template = effectiveParser.resolveTemplate(template, variables, context: context);
    if (body != null) {
      body = effectiveParser.resolveTemplate(body, variables, context: context);
    }

    // 4. Resolve relative URL
    template = resolveUrl(host, template);

    return ResolvedSearchUrl(
      url: template,
      isPost: isPost,
      body: body,
      headers: headers,
    );
  }

  /// Parse a header string in `key=value&key2=value2` format.
  static Map<String, String> parseHeaderString(String headerStr) {
    final headers = <String, String>{};
    for (final pair in headerStr.split('&')) {
      final eqIdx = pair.indexOf('=');
      if (eqIdx >= 0) {
        headers[pair.substring(0, eqIdx)] = pair.substring(eqIdx + 1);
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
    final resolved = SearchUrlResolver.resolve(
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
    );
  }
}
