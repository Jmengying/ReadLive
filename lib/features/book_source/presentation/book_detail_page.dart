import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/core/network/url_utils.dart';
import 'package:readlive/features/book_source/presentation/book_source_provider.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';
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

      _resolvedBookUrl = resolveUrl(source.host, widget.bookUrl);
      debugPrint('BookDetail: bookUrl=${widget.bookUrl}, resolved=$_resolvedBookUrl');
      debugPrint('BookDetail: source.host=${source.host}');
      debugPrint('BookDetail: rule.toc=${rule.toc != null}, toc.list=${rule.toc?.list}');

      final bookHtml = await fetcher.fetch(_resolvedBookUrl!);
      debugPrint('BookDetail: bookHtml=${bookHtml.length} bytes');

      if (rule.bookInfo != null) {
        _bookInfo = await extractor.extractBookInfo(bookHtml, rule.bookInfo!, baseUrl: source.host);
      }

      String tocUrl;
      if (_bookInfo?.tocUrl != null && _bookInfo!.tocUrl!.isNotEmpty) {
        tocUrl = resolveUrl(source.host,
            parser.resolveTemplate(_bookInfo!.tocUrl!, {'bookUrl': _resolvedBookUrl!}));
      } else {
        tocUrl = _resolvedBookUrl!;
      }
      debugPrint('BookDetail: tocUrl=$tocUrl');

      final tocHtml = await fetcher.fetch(tocUrl);
      debugPrint('BookDetail: tocHtml=${tocHtml.length} bytes');

      if (rule.toc != null) {
        _chapters = await extractor.extractToc(tocHtml, rule.toc!, baseUrl: source.host);
        debugPrint('BookDetail: chapters=${_chapters.length}');
      } else {
        debugPrint('BookDetail: rule.toc is NULL');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('BookDetail ERROR: $e');
      debugPrint('BookDetail STACK: $stackTrace');
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
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
                                    onPressed: () async {
                                      final book = await _addToBookshelf();
                                      if (book != null && mounted) {
                                        context.pop();
                                      }
                                    },
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
                            onTap: () => _openReader(index),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _openReader(int chapterIndex) async {
    final repo = ref.read(bookRepositoryProvider);

    // Check if already in bookshelf
    final allBooks = await repo.getAllBooks();
    BookEntity? existing;
    for (final b in allBooks) {
      if (b.sourceId == widget.sourceId && b.bookUrl == _resolvedBookUrl) {
        existing = b;
        break;
      }
    }

    BookEntity book;
    if (existing != null) {
      book = existing;
    } else {
      final added = await _addToBookshelf();
      if (added == null) return;
      book = added;
    }

    if (mounted) {
      context.push('/reader/${book.id}?chapter=$chapterIndex');
    }
  }

  Future<BookEntity?> _addToBookshelf() async {
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

      // Save chapter list to database
      if (_chapters.isNotEmpty) {
        final uuid = const Uuid();
        final now = DateTime.now().millisecondsSinceEpoch;
        final companions = <ChaptersTableCompanion>[];
        for (var i = 0; i < _chapters.length; i++) {
          companions.add(ChaptersTableCompanion(
            id: Value(uuid.v4()),
            bookId: Value(book.id),
            title: Value(_chapters[i].title),
            url: Value(_chapters[i].url),
            content: const Value(null),
            chapterIndex: Value(i),
            isCached: const Value(false),
            createdAt: Value(now),
          ));
        }
        await repo.insertChapters(book.id, companions);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加入书架: ${book.title}')),
        );
      }
      return book;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入书架失败: $e')),
        );
      }
      return null;
    }
  }
}
