import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/reader/domain/chapter_entity.dart';
import 'package:readlive/features/reader/presentation/reader_provider.dart';
import 'package:readlive/features/reader/presentation/widgets/text_content_view.dart';
import 'package:readlive/features/reader/presentation/widgets/reader_toolbar.dart';

class ReaderPage extends ConsumerStatefulWidget {
  final String bookId;
  const ReaderPage({super.key, required this.bookId});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(currentBookProvider(widget.bookId));
    final chaptersAsync = ref.watch(chaptersProvider(widget.bookId));
    final readerState = ref.watch(readerNotifierProvider(widget.bookId));
    final notifier = ref.read(readerNotifierProvider(widget.bookId).notifier);

    return Scaffold(
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('书籍不存在'));
          }

          return chaptersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载章节失败: $e')),
            data: (chapters) {
              if (chapters.isEmpty) {
                return const Center(child: Text('暂无章节内容'));
              }

              final chapterIndex = readerState.currentChapterIndex.clamp(
                  0, chapters.length - 1);
              final screenSize = MediaQuery.of(context).size;

              final pagesAsync = ref.watch(chapterPagesProvider((
                bookId: widget.bookId,
                chapterIndex: chapterIndex,
                screenWidth: screenSize.width,
                screenHeight: screenSize.height,
              )));

              return pagesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('分页失败: $e')),
                data: (pages) {
                  if (pages.isEmpty) {
                    return const Center(child: Text('章节内容为空'));
                  }

                  final pageIndex = readerState.currentPageIndex.clamp(
                      0, pages.length - 1);

                  return GestureDetector(
                    onTapUp: (details) => _handleTap(
                        details, screenSize, notifier, pages.length),
                    onDoubleTap: () {
                      if (readerState.isLocked) {
                        notifier.toggleLock();
                      }
                    },
                    child: Stack(
                      children: [
                        // Content
                        TextContentView(
                          text: pages[pageIndex].text,
                          fontSize: 18,
                          lineHeight: 1.8,
                        ),
                        // Toolbar overlay
                        if (readerState.isToolbarVisible)
                          ReaderToolbar(
                            bookTitle: book.title,
                            currentChapter: chapterIndex,
                            totalChapters: chapters.length,
                            isLocked: readerState.isLocked,
                            onBack: () => context.pop(),
                            onToggleLock: notifier.toggleLock,
                            onShowChapters: () =>
                                _showChapterDrawer(chapters),
                            onShowSettings: () {},
                            onToggleNightMode: () {},
                            onChapterChange: (index) {
                              notifier.setChapter(index);
                            },
                          ),
                        // Lock indicator
                        if (readerState.isLocked)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('已锁定',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(TapUpDetails details, Size screenSize,
      ReaderNotifier notifier, int totalPages) {
    if (ref.read(readerNotifierProvider(widget.bookId)).isLocked) {
      return;
    }

    final dx = details.globalPosition.dx;
    final width = screenSize.width;

    if (dx < width * 0.3) {
      notifier.previousPage();
    } else if (dx > width * 0.7) {
      notifier.nextPage(totalPages);
    } else {
      notifier.toggleToolbar();
    }
  }

  void _showChapterDrawer(List<ChapterEntity> chapters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text('目录',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: chapters.length,
                itemBuilder: (ctx, index) => ListTile(
                  title: Text(chapters[index].title),
                  onTap: () {
                    ref
                        .read(
                            readerNotifierProvider(widget.bookId).notifier)
                        .setChapter(index);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
