import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:readlive/core/network/url_utils.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/data/html_fetcher.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
import 'package:readlive/features/book_source/domain/source_rule.dart';

class ChapterCrawler {
  final HtmlFetcher _fetcher;
  final ContentExtractor _extractor;
  static const _maxPages = 20;

  ChapterCrawler({
    HtmlFetcher? fetcher,
    ContentExtractor? extractor,
  })  : _fetcher = fetcher ?? HtmlFetcher(),
        _extractor = extractor ?? ContentExtractor();

  /// Fetch the full text content for a single chapter.
  ///
  /// Handles multi-page chapters by following nextPage links.
  /// Returns the concatenated chapter text from all pages.
  Future<String> fetchChapterContent({
    required String chapterUrl,
    required ContentRule contentRule,
    required String host,
    CancelToken? cancelToken,
  }) async {
    final context = RuleContext();
    final parts = <String>[];
    var url = chapterUrl;
    var pageCount = 0;

    while (url.isNotEmpty && pageCount < _maxPages) {
      if (cancelToken?.isCancelled == true) break;

      final encoding = contentRule.encoding.toLowerCase() != 'utf-8'
          ? contentRule.encoding
          : null;

      final html = await _fetcher.fetch(
        url,
        encoding: encoding,
        cancelToken: cancelToken,
      );

      final content = _extractor.extractChapterContent(html, contentRule, context: context);
      if (content.isNotEmpty) {
        parts.add(content);
      }

      // Check for next page
      final nextPageUrl = _extractor.extractNextPageUrl(
        html,
        contentRule.nextPage,
        context: context,
      );

      if (nextPageUrl != null && nextPageUrl.isNotEmpty) {
        url = resolveUrl(host, nextPageUrl);
      } else {
        url = '';
      }

      pageCount++;
    }

    return parts.join('\n\n');
  }

  /// Fetch image URLs for a manga chapter.
  ///
  /// Returns a JSON-encoded string of absolute image URL list.
  /// Handles multi-page chapters by following nextPage links.
  Future<String> fetchChapterImages({
    required String chapterUrl,
    required ContentRule contentRule,
    required String host,
    CancelToken? cancelToken,
  }) async {
    final context = RuleContext();
    final allUrls = <String>[];
    var url = chapterUrl;
    var pageCount = 0;

    while (url.isNotEmpty && pageCount < _maxPages) {
      if (cancelToken?.isCancelled == true) break;

      final encoding = contentRule.encoding.toLowerCase() != 'utf-8'
          ? contentRule.encoding
          : null;

      final html = await _fetcher.fetch(
        url,
        encoding: encoding,
        cancelToken: cancelToken,
      );

      final imageUrls = _extractor.extractImageUrls(html, contentRule.images);
      for (final imgUrl in imageUrls) {
        allUrls.add(resolveUrl(host, imgUrl));
      }

      // Check for next page
      final nextPageUrl = _extractor.extractNextPageUrl(
        html,
        contentRule.nextPage,
        context: context,
      );

      if (nextPageUrl != null && nextPageUrl.isNotEmpty) {
        url = resolveUrl(host, nextPageUrl);
      } else {
        url = '';
      }

      pageCount++;
    }

    return jsonEncode(allUrls);
  }
}
