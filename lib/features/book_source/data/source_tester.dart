import 'package:readlive/core/network/url_utils.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/data/html_fetcher.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
import 'package:readlive/features/book_source/data/rule_parser.dart';
import 'package:readlive/features/book_source/domain/book_source_entity.dart';

class SourceTestResult {
  final bool success;
  final bool? searchOk;
  final bool? tocOk;
  final bool? contentOk;
  final int? responseTimeMs;
  final int? resultCount;
  final int? chapterCount;
  final int? contentLength;
  final String? errorMessage;

  const SourceTestResult({
    required this.success,
    this.searchOk,
    this.tocOk,
    this.contentOk,
    this.responseTimeMs,
    this.resultCount,
    this.chapterCount,
    this.contentLength,
    this.errorMessage,
  });

  String get summary {
    if (!success) return '测试失败: ${errorMessage ?? "未知错误"}';
    final parts = <String>[];
    if (searchOk == true) parts.add('搜索✓($resultCount条)');
    if (searchOk == false) parts.add('搜索✗');
    if (tocOk == true) parts.add('目录✓($chapterCount章)');
    if (tocOk == false) parts.add('目录✗');
    if (contentOk == true) parts.add('正文✓($contentLength字)');
    if (contentOk == false) parts.add('正文✗');
    parts.add('${responseTimeMs}ms');
    return parts.join(' ');
  }
}

class SourceTester {
  final HtmlFetcher _fetcher;
  final ContentExtractor _extractor;
  final RuleParser _parser;
  static const _testKeyword = '斗破苍穹';

  SourceTester({
    HtmlFetcher? fetcher,
    ContentExtractor? extractor,
    RuleParser? parser,
  })  : _fetcher = fetcher ?? HtmlFetcher(),
        _extractor = extractor ?? ContentExtractor(),
        _parser = parser ?? RuleParser();

  Future<SourceTestResult> testSource(BookSourceEntity source) async {
    final context = RuleContext();
    final stopwatch = Stopwatch()..start();
    bool? searchOk;
    bool? tocOk;
    bool? contentOk;
    int? resultCount;
    int? chapterCount;
    int? contentLength;
    String firstBookUrl = '';
    String firstChapterUrl = '';

    try {
      final rule = source.parseRule();

      // Step 1: Test search
      if (rule.search != null) {
        try {
          final rawUrl = _parser.resolveTemplate(
            rule.search!.url,
            {'key': _testKeyword, 'page': '1'},
            context: context,
          );

          // Handle @post: prefix (Legado format)
          final String html;
          if (rawUrl.startsWith('@post:')) {
            final postBody = rawUrl.substring(6);
            final parts = postBody.split(',');
            final postUrl = resolveUrl(source.host, parts.first.trim());
            final postData = parts.length > 1 ? parts.sublist(1).join(',').trim() : null;
            html = await _fetcher.post(postUrl, data: postData);
          } else {
            html = await _fetcher.fetch(resolveUrl(source.host, rawUrl));
          }

          final results = _extractor.extractSearchResults(
            html, rule.search!, source.id, source.name, context: context,
          );
          resultCount = results.length;
          searchOk = results.isNotEmpty;
          if (results.isNotEmpty) {
            firstBookUrl = results.first.bookUrl;
          }
        } catch (_) {
          searchOk = false;
        }
      }

      // Step 2: Test TOC (only if search succeeded and we have a book URL)
      if (searchOk == true && firstBookUrl.isNotEmpty && rule.toc != null) {
        try {
          final bookUrl = resolveUrl(source.host, firstBookUrl);
          final bookHtml = await _fetcher.fetch(bookUrl);

          String tocUrl = bookUrl;
          if (rule.bookInfo?.tocUrl != null &&
              rule.bookInfo!.tocUrl!.isNotEmpty) {
            final tocUrlPart = _parser.resolveTemplate(
              rule.bookInfo!.tocUrl!, {'bookUrl': bookUrl},
              context: context,
            );
            tocUrl = resolveUrl(source.host, tocUrlPart);
          }

          final tocHtml = tocUrl == bookUrl
              ? bookHtml
              : await _fetcher.fetch(tocUrl);

          final chapters = _extractor.extractToc(tocHtml, rule.toc!, context: context);
          chapterCount = chapters.length;
          tocOk = chapters.isNotEmpty;
          if (chapters.isNotEmpty) {
            firstChapterUrl = chapters.first.url;
          }
        } catch (_) {
          tocOk = false;
        }
      }

      // Step 3: Test content (only if TOC succeeded)
      if (tocOk == true && firstChapterUrl.isNotEmpty && rule.content != null) {
        try {
          final chapterUrl = resolveUrl(source.host, firstChapterUrl);
          final encoding = rule.content!.encoding.toLowerCase() != 'utf-8'
              ? rule.content!.encoding
              : null;
          final html = await _fetcher.fetch(chapterUrl, encoding: encoding);
          final content = _extractor.extractChapterContent(html, rule.content!, context: context);
          contentLength = content.length;
          contentOk = content.length > 100;
        } catch (_) {
          contentOk = false;
        }
      }

      stopwatch.stop();
      final success = (searchOk ?? true) &&
          (tocOk ?? true) &&
          (contentOk ?? true);

      return SourceTestResult(
        success: success,
        searchOk: searchOk,
        tocOk: tocOk,
        contentOk: contentOk,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        resultCount: resultCount,
        chapterCount: chapterCount,
        contentLength: contentLength,
      );
    } catch (e) {
      stopwatch.stop();
      return SourceTestResult(
        success: false,
        searchOk: searchOk,
        tocOk: tocOk,
        contentOk: contentOk,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        resultCount: resultCount,
        chapterCount: chapterCount,
        contentLength: contentLength,
        errorMessage: e.toString(),
      );
    }
  }
}
