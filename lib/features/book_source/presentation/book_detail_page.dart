import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/book_source/presentation/book_source_provider.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  final String bookUrl;
  final String sourceId;
  final String bookName;

  const BookDetailPage({
    super.key,
    required this.bookUrl,
    required this.sourceId,
    required this.bookName,
  });

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  BookInfo? _bookInfo;
  List<TocEntry> _chapters = [];
  bool _isLoading = true;
  String? _error;
  String? _resolvedBookUrl;

  @override
  void initState() {
    super.initState();
    _loadBookDetail();
  }

  Future<void> _loadBookDetail() async {
    try {
      final repo = ref.read(bookSourceRepositoryProvider);
      final source = await repo.getSourceById(widget.sourceId);
      if (source == null) {
        setState(() {
          _error = '书源不存在';
          _isLoading = false;
        });
        return;
      }

      final rule = source.parseRule();
      final fetcher = ref.read(htmlFetcherProvider);
      final extractor = ref.read(contentExtractorProvider);
      final parser = ref.read(ruleParserProvider);

      _resolvedBookUrl = _resolveUrl(source.host, widget.bookUrl);

      final bookHtml = await fetcher.fetch(_resolvedBookUrl!);

      if (rule.bookInfo != null) {
        _bookInfo = extractor.extractBookInfo(bookHtml, rule.bookInfo!);
      }

      String tocUrl;
      if (_bookInfo?.tocUrl != null && _bookInfo!.tocUrl!.isNotEmpty) {
        tocUrl = _resolveUrl(source.host,
            parser.resolveTemplate(_bookInfo!.tocUrl!, {'bookUrl': _resolvedBookUrl!}));
      } else {
        tocUrl = _resolvedBookUrl!;
      }

      final tocHtml = await fetcher.fetch(tocUrl);

      if (rule.toc != null) {
        _chapters = extractor.extractToc(tocHtml, rule.toc!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  String _resolveUrl(String host, String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    if (url.startsWith('/')) {
      final uri = Uri.parse(host);
      return '${uri.scheme}://${uri.host}$url';
    }
    return '$host/$url';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.bookName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 112,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  widget.bookName.substring(
                                      0, widget.bookName.length.clamp(0, 4)),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.bookName,
                                      style: theme.textTheme.titleLarge),
                                  if (_bookInfo?.author != null) ...[
                                    const SizedBox(height: 4),
                                    Text('作者: ${_bookInfo!.author}',
                                        style: theme.textTheme.bodyMedium),
                                  ],
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('加入书架'),
                                    onPressed: _addToBookshelf,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_bookInfo?.intro != null &&
                          _bookInfo!.intro!.isNotEmpty) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _bookInfo!.intro!,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text('目录 (${_chapters.length}章)',
                            style: theme.textTheme.titleMedium),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          return ListTile(
                            dense: true,
                            title: Text(chapter.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              // Will open reader at this chapter in future
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _addToBookshelf() async {
    try {
      final repo = ref.read(bookRepositoryProvider);
      final source = await ref.read(bookSourceRepositoryProvider)
          .getSourceById(widget.sourceId);

      final book = await repo.addBook(
        title: widget.bookName,
        author: _bookInfo?.author,
        sourceId: widget.sourceId,
        bookUrl: _resolvedBookUrl,
        contentType: source?.contentType ?? 'novel',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加入书架: ${book.title}')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入书架失败: $e')),
        );
      }
    }
  }
}
