import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/network/url_utils.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/presentation/book_source_provider.dart';
import 'package:readlive/features/book_source/domain/search_result.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';

class SwitchSourceSheet extends ConsumerStatefulWidget {
  final String bookId;
  final String bookTitle;
  final String? currentSourceId;

  const SwitchSourceSheet({
    super.key,
    required this.bookId,
    required this.bookTitle,
    this.currentSourceId,
  });

  @override
  ConsumerState<SwitchSourceSheet> createState() => _SwitchSourceSheetState();
}

class _SwitchSourceSheetState extends ConsumerState<SwitchSourceSheet> {
  List<SearchResult> _results = [];
  bool _isLoading = true;
  String? _error;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(bookSourceRepositoryProvider);
      final sources = await repo.getEnabledSources();
      final fetcher = ref.read(htmlFetcherProvider);
      final extractor = ref.read(contentExtractorProvider);
      final parser = ref.read(ruleParserProvider);

      final allResults = <SearchResult>[];
      for (final source in sources) {
        if (source.id == widget.currentSourceId) continue;
        try {
          final rule = source.parseRule();
          if (rule.search == null) continue;
          final url = parser.resolveTemplate(
            rule.search!.url,
            {'key': widget.bookTitle, 'page': '1'},
          );
          final html = await fetcher.fetch(resolveUrl(source.host, url));
          final results = extractor.extractSearchResults(
            html, rule.search!, source.id, source.name,
          );
          // Filter to results that roughly match the book title
          final matching = results.where((r) =>
              r.bookName.contains(widget.bookTitle) ||
              widget.bookTitle.contains(r.bookName));
          allResults.addAll(matching.isNotEmpty ? matching : results.take(1));
        } catch (_) {
          // Skip failed sources
        }
      }

      setState(() {
        _results = allResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '搜索失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _switchToSource(SearchResult result) async {
    setState(() => _isSwitching = true);

    try {
      final repo = ref.read(bookSourceRepositoryProvider);
      final source = await repo.getSourceById(result.sourceId);
      if (source == null) throw Exception('书源不存在');

      final rule = source.parseRule();
      final fetcher = ref.read(htmlFetcherProvider);
      final extractor = ref.read(contentExtractorProvider);
      final parser = ref.read(ruleParserProvider);

      // Fetch book detail page
      final bookUrl = resolveUrl(source.host, result.bookUrl);
      final bookHtml = await fetcher.fetch(bookUrl);

      BookInfo? bookInfo;
      if (rule.bookInfo != null) {
        bookInfo = extractor.extractBookInfo(bookHtml, rule.bookInfo!);
      }

      // Fetch TOC
      String tocUrl = bookUrl;
      if (bookInfo?.tocUrl != null && bookInfo!.tocUrl!.isNotEmpty) {
        tocUrl = resolveUrl(
            source.host,
            parser.resolveTemplate(bookInfo.tocUrl!, {'bookUrl': bookUrl}));
      }
      final tocHtml = tocUrl == bookUrl
          ? bookHtml
          : await fetcher.fetch(tocUrl);

      List<TocEntry> newChapters = [];
      if (rule.toc != null) {
        newChapters = extractor.extractToc(tocHtml, rule.toc!);
      }

      if (newChapters.isEmpty) {
        throw Exception('未获取到章节列表');
      }

      // Switch source in database
      final bookRepo = ref.read(bookRepositoryProvider);
      await bookRepo.switchSource(
        widget.bookId,
        source.id,
        bookUrl,
        newChapters,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已切换到 ${source.name}，共${newChapters.length}章')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('换源失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('换源', style: theme.textTheme.titleLarge),
                  const SizedBox(width: 8),
                  Text('搜索: ${widget.bookTitle}',
                      style: theme.textTheme.bodySmall),
                  const Spacer(),
                  if (_isSwitching)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _search,
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        )
                      : _results.isEmpty
                          ? const Center(child: Text('未找到其他源'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final result = _results[index];
                                return ListTile(
                                  title: Text(result.bookName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                    '${result.author ?? "未知"} · ${result.sourceName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.swap_horiz),
                                  onTap: _isSwitching
                                      ? null
                                      : () => _switchToSource(result),
                                );
                              },
                            ),
            ),
          ],
        );
      },
    );
  }
}
