import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:readlive/core/theme/app_theme.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';
import 'package:readlive/features/reader/domain/chapter_entity.dart';
import 'package:readlive/features/reader/presentation/reader_provider.dart';
import 'package:readlive/features/reader/presentation/widgets/text_content_view.dart';
import 'package:readlive/features/reader/presentation/widgets/reader_toolbar.dart';
import 'package:readlive/features/reader/presentation/widgets/reading_settings_panel.dart';
import 'package:readlive/features/reader/presentation/widgets/bookmark_list_sheet.dart';
import 'package:readlive/features/reader/presentation/widgets/tts_controls.dart';

class ReaderPage extends ConsumerStatefulWidget {
  final String bookId;
  const ReaderPage({super.key, required this.bookId});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  bool _showTts = false;
  bool _isNightMode = false;

  @override
  void initState() {
    super.initState();
    _enableWakelock();
    ref.listenManual(readingSettingsProvider, (prev, next) {
      if (prev?.keepScreenOn != next.keepScreenOn) {
        if (next.keepScreenOn) {
          WakelockPlus.enable();
        } else {
          WakelockPlus.disable();
        }
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _enableWakelock() async {
    final settings = ref.read(readingSettingsProvider);
    if (settings.keepScreenOn) {
      await WakelockPlus.enable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(currentBookProvider(widget.bookId));
    final chaptersAsync = ref.watch(chaptersProvider(widget.bookId));
    final readerState = ref.watch(readerNotifierProvider(widget.bookId));
    final notifier = ref.read(readerNotifierProvider(widget.bookId).notifier);
    final readingSettings = ref.watch(readingSettingsProvider);

    final bgIndex = _isNightMode ? 4 : readingSettings.bgIndex;
    final bgColor = AppTheme.readingBackgrounds[bgIndex];
    final textColor = bgIndex >= 3
        ? AppTheme.readingTextColors[1]
        : AppTheme.readingTextColors[0];

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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('分页失败: $e')),
                data: (pages) {
                  if (pages.isEmpty) {
                    return const Center(child: Text('章节内容为空'));
                  }

                  final pageIndex = readerState.currentPageIndex.clamp(
                      0, pages.length - 1);

                  return GestureDetector(
                    onTapUp: (details) => _handleTap(
                        details, screenSize, notifier, pages.length,
                        readingSettings),
                    onDoubleTap: () {
                      if (readerState.isLocked) {
                        notifier.toggleLock();
                      }
                    },
                    child: Stack(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            switch (readingSettings.pageAnimation) {
                              case 'fade':
                                return FadeTransition(
                                    opacity: animation, child: child);
                              case 'scroll':
                              case 'none':
                                return child;
                              case 'slide':
                              default:
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                );
                            }
                          },
                          child: TextContentView(
                            key: ValueKey('$chapterIndex-$pageIndex'),
                            text: pages[pageIndex].text,
                            fontSize: readingSettings.fontSize,
                            lineHeight: readingSettings.lineHeight,
                            textColor: textColor,
                            backgroundColor: bgColor,
                            fontFamily: readingSettings.fontFamily,
                            fontWeight: readingSettings.fontWeight,
                            firstLineIndent: readingSettings.firstLineIndent,
                            eyeProtection: readingSettings.eyeProtection,
                          ),
                        ),
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
                            onShowSettings: () => _showSettingsPanel(),
                            onShowBookmarks: () => _showBookmarkSheet(
                                chapters[chapterIndex]),
                            onToggleNightMode: _toggleNightMode,
                            onToggleTts: _toggleTts,
                            onAddBookmark: () => _addBookmark(
                                chapters[chapterIndex], pageIndex),
                            onChapterChange: (index) {
                              notifier.setChapter(index);
                            },
                          ),
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
                        if (_showTts)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: TtsControls(
                              text: pages[pageIndex].text,
                              onClose: () => setState(() => _showTts = false),
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
      ReaderNotifier notifier, int totalPages, ReadingSettings settings) {
    final dx = details.globalPosition.dx;
    final width = screenSize.width;

    if (ref.read(readerNotifierProvider(widget.bookId)).isLocked) {
      return;
    }

    final leftBound = width * settings.tapZoneLeft;
    final rightBound = width * (1 - settings.tapZoneRight);

    if (dx < leftBound) {
      notifier.previousPage();
    } else if (dx > rightBound) {
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: chapters.length,
                itemBuilder: (ctx, index) => ListTile(
                  title: Text(chapters[index].title),
                  onTap: () {
                    ref
                        .read(readerNotifierProvider(widget.bookId).notifier)
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

  void _showSettingsPanel() {
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const ReadingSettingsPanel(),
    );
  }

  void _showBookmarkSheet(ChapterEntity chapter) {
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BookmarkListSheet(
        bookId: widget.bookId,
        onJumpToBookmark: (chapterIndex, position) {
          final notifier =
              ref.read(readerNotifierProvider(widget.bookId).notifier);
          notifier.setChapter(chapterIndex);
          notifier.setPage(position);
        },
      ),
    );
  }

  void _toggleNightMode() {
    setState(() => _isNightMode = !_isNightMode);
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
  }

  void _toggleTts() {
    setState(() => _showTts = !_showTts);
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
  }

  Future<void> _addBookmark(ChapterEntity chapter, int pageIndex) async {
    final repo = ref.read(bookmarkRepositoryProvider);
    await repo.addBookmark(
      bookId: widget.bookId,
      chapterId: chapter.id,
      position: pageIndex,
      contentPreview: chapter.title,
    );
    ref.invalidate(bookmarksProvider(widget.bookId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加书签')),
      );
    }
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
  }
}
