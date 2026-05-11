import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/core/theme/app_theme.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';
import 'package:readlive/features/reader/domain/chapter_entity.dart';
import 'package:readlive/features/reader/presentation/reader_provider.dart';
import 'package:readlive/features/reader/presentation/widgets/text_content_view.dart';
import 'package:readlive/features/reader/presentation/widgets/manga_content_view.dart';
import 'package:readlive/features/reader/presentation/widgets/reader_toolbar.dart';
import 'package:readlive/features/reader/presentation/widgets/reading_settings_panel.dart';
import 'package:readlive/features/book_source/presentation/switch_source_sheet.dart';
import 'package:readlive/features/reader/presentation/widgets/bookmark_list_sheet.dart';
import 'package:readlive/features/reader/presentation/widgets/tts_controls.dart';

class ReaderPage extends ConsumerStatefulWidget {
  final String bookId;
  final int initialChapter;
  const ReaderPage({super.key, required this.bookId, this.initialChapter = 0});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  bool _showTts = false;
  final ScrollController _scrollController = ScrollController();
  int _lastScrollChapterIndex = -1;
  bool _initialPageRestored = false;
  double _pendingScrollRestore = -1;
  late DateTime _segmentStartTime;
  Timer? _saveTimer;
  Timer? _scrollSaveTimer;

  @override
  void initState() {
    super.initState();
    _segmentStartTime = DateTime.now();
    _enableWakelock();
    // Save reading session every 30 seconds
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) => _saveSegment());
    // Save scroll position 1 second after user stops scrolling
    _scrollController.addListener(_onScroll);
    if (widget.initialChapter > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(readerNotifierProvider(widget.bookId).notifier)
            .setChapter(widget.initialChapter);
      });
    }
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
    _saveTimer?.cancel();
    _scrollSaveTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    // Save scroll position synchronously before disposing
    _saveScrollPositionSync();
    // Save final reading session before disposing
    _saveSegmentSync();
    _scrollController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _onScroll() {
    _scrollSaveTimer?.cancel();
    _scrollSaveTimer = Timer(const Duration(seconds: 1), _saveScrollPosition);
  }

  void _saveScrollPosition() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final progress = maxScroll > 0 ? (_scrollController.offset / maxScroll).clamp(0.0, 1.0) : 0.0;
    final readerState = ref.read(readerNotifierProvider(widget.bookId));
    final bookRepo = ref.read(bookRepositoryProvider);
    bookRepo.updateReadingPosition(
      widget.bookId,
      readerState.currentChapterIndex,
      _scrollController.offset,
      progress: progress,
    );
  }

  void _saveScrollPositionSync() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final progress = maxScroll > 0 ? (_scrollController.offset / maxScroll).clamp(0.0, 1.0) : 0.0;
    final readerState = ref.read(readerNotifierProvider(widget.bookId));
    final bookRepo = ref.read(bookRepositoryProvider);
    bookRepo.updateReadingPosition(
      widget.bookId,
      readerState.currentChapterIndex,
      _scrollController.offset,
      progress: progress,
    );
  }

  void _tryRestoreScrollPosition(int chapterIndex, BookEntity book) {
    // Fetch fresh data from DB (provider may have stale cache)
    final bookRepo = ref.read(bookRepositoryProvider);
    bookRepo.getBookById(widget.bookId).then((freshBook) {
      if (freshBook == null) return;
      final savedProgress = freshBook.progress;
      final savedChapter = freshBook.lastChapterIndex;
      if (savedProgress <= 0 || chapterIndex != savedChapter) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll <= 0) {
          // Layout not done yet, retry next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollController.hasClients) return;
            final ms = _scrollController.position.maxScrollExtent;
            if (ms > 0) {
              _scrollController.jumpTo(ms * savedProgress);
            }
          });
          return;
        }
        _scrollController.jumpTo(maxScroll * savedProgress);
      });
    });
  }

  void _saveSegmentSync() {
    try {
      final now = DateTime.now();
      final durationSeconds = now.difference(_segmentStartTime).inSeconds;
      // Skip session save if reading time is too short (progress already saved by _saveScrollPositionSync)
      if (durationSeconds < 3) return;

      int wordsRead = 0;
      final chaptersValue = ref.read(chaptersProvider(widget.bookId)).valueOrNull;
      if (chaptersValue != null) {
        final readerState = ref.read(readerNotifierProvider(widget.bookId));
        final idx = readerState.currentChapterIndex.clamp(0, chaptersValue.length - 1);
        wordsRead = (chaptersValue[idx].content ?? '').length;
      }

      final db = ref.read(databaseProvider);
      db.insertReadingSession(ReadingSessionsTableCompanion(
        id: Value(const Uuid().v4()),
        bookId: Value(widget.bookId),
        startTime: Value(_segmentStartTime.millisecondsSinceEpoch),
        endTime: Value(now.millisecondsSinceEpoch),
        durationSeconds: Value(durationSeconds),
        wordsRead: Value(wordsRead),
      ));

      // Reset for next segment
      _segmentStartTime = now;
      // Bump refresh counter synchronously
      ref.read(statsRefreshProvider.notifier).state++;
    } catch (_) {
      // Ignore errors during dispose
    }
  }

  void _saveSegment() {
    final now = DateTime.now();
    final durationSeconds = now.difference(_segmentStartTime).inSeconds;
    if (durationSeconds < 3) return;

    int wordsRead = 0;
    final chaptersValue = ref.read(chaptersProvider(widget.bookId)).valueOrNull;
    if (chaptersValue != null) {
      final readerState = ref.read(readerNotifierProvider(widget.bookId));
      final idx = readerState.currentChapterIndex.clamp(0, chaptersValue.length - 1);
      wordsRead = (chaptersValue[idx].content ?? '').length;
    }

    // Save reading position
    final readerState = ref.read(readerNotifierProvider(widget.bookId));
    final bookRepo = ref.read(bookRepositoryProvider);
    final settings = ref.read(readingSettingsProvider);
    final isScrollMode = settings.pageAnimation == 'scroll';
    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final maxScroll = _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0.0;
    final progress = isScrollMode && maxScroll > 0 ? (scrollOffset / maxScroll).clamp(0.0, 1.0) : 0.0;
    bookRepo.updateReadingPosition(
      widget.bookId,
      readerState.currentChapterIndex,
      scrollOffset,
      pageIndex: readerState.currentPageIndex,
      progress: progress,
    );

    final db = ref.read(databaseProvider);
    db.insertReadingSession(ReadingSessionsTableCompanion(
      id: Value(const Uuid().v4()),
      bookId: Value(widget.bookId),
      startTime: Value(_segmentStartTime.millisecondsSinceEpoch),
      endTime: Value(now.millisecondsSinceEpoch),
      durationSeconds: Value(durationSeconds),
      wordsRead: Value(wordsRead),
    ));

    // Reset for next segment
    _segmentStartTime = now;
    // Bump refresh counter synchronously
    ref.read(statsRefreshProvider.notifier).state++;
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

    final bgIndex = readingSettings.isNightMode ? 4 : readingSettings.bgIndex;
    final Color bgColor;
    if (!readingSettings.isNightMode && readingSettings.customBgColor >= 0) {
      bgColor = Color(readingSettings.customBgColor);
    } else {
      bgColor = AppTheme.readingBackgrounds[bgIndex];
    }
    final textColor = ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark
        ? AppTheme.readingTextColors[1]
        : AppTheme.readingTextColors[0];

    // Brightness overlay: darken screen when brightness < 1.0
    final brightnessValue = readingSettings.brightness;
    final showBrightnessOverlay = brightnessValue >= 0 && brightnessValue < 1.0;

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
              final isScrollMode = readingSettings.pageAnimation == 'scroll';

              // Mark chapter change in scroll mode (actual restore happens after content loads)
              if (isScrollMode && _lastScrollChapterIndex != chapterIndex) {
                _lastScrollChapterIndex = chapterIndex;
              }

              if (isScrollMode) {
                // Scroll mode: show entire chapter with vertical scrolling
                final contentAsync = ref.watch(chapterContentProvider((
                  bookId: widget.bookId,
                  chapterIndex: chapterIndex,
                )));

                return contentAsync.when(
                  loading: () => Container(
                    color: bgColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text('正在加载章节内容...',
                              style: TextStyle(color: textColor)),
                        ],
                      ),
                    ),
                  ),
                  error: (e, _) => Container(
                    color: bgColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 16),
                          Text('加载失败: $e',
                              style: TextStyle(color: textColor)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试'),
                            onPressed: () => ref.invalidate(
                                chapterContentProvider((
                              bookId: widget.bookId,
                              chapterIndex: chapterIndex,
                            ))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (chapterContent) {
                    final isManga = book.contentType == 'manga';

                    // Restore scroll position now that content is loaded
                    _tryRestoreScrollPosition(chapterIndex, book);

                    return GestureDetector(
                      onTapUp: (details) {
                        if (isManga) {
                          _handleMangaTap(details, screenSize, notifier);
                        }
                      },
                      onDoubleTap: () {
                        if (readerState.isLocked) {
                          notifier.toggleLock();
                        } else {
                          notifier.toggleToolbar();
                        }
                      },
                      child: Stack(
                        children: [
                          _buildBackgroundContainer(
                            bgColor: bgColor,
                            bgImagePath: readingSettings.bgImagePath,
                            child: isManga
                                ? MangaContentView(
                                    imageUrls: _parseImageUrls(chapterContent),
                                    readingMode: 'scroll',
                                    backgroundColor: bgColor,
                                  )
                                : SingleChildScrollView(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    child: TextContentView(
                                      text: chapterContent,
                                      fontSize: readingSettings.fontSize,
                                      lineHeight: readingSettings.lineHeight,
                                      textColor: textColor,
                                      backgroundColor: bgColor,
                                      fontFamily: readingSettings.fontFamily,
                                      fontWeight: readingSettings.fontWeight,
                                      firstLineIndent: readingSettings.firstLineIndent,
                                      letterSpacing: readingSettings.letterSpacing,
                                      eyeProtection: readingSettings.eyeProtection,
                                      eyeProtectionIntensity: readingSettings.eyeProtectionIntensity,
                                      scrollable: false,
                                    ),
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
                              onShowChapters: () => _showChapterDrawer(chapters),
                              onShowSettings: () => _showSettingsPanel(),
                              onShowBookmarks: () =>
                                  _showBookmarkSheet(chapters[chapterIndex]),
                              onToggleNightMode: _toggleNightMode,
                              onToggleTts: _toggleTts,
                              onAddBookmark: () =>
                                  _addBookmark(chapters[chapterIndex], 0),
                              onChapterChange: (index) {
                                _saveScrollPosition();
                                notifier.setChapter(index);
                              },
                              onSwitchSource: book.sourceId != null
                                  ? () => _showSwitchSourceSheet(book)
                                  : null,
                              onPreviousChapter: chapterIndex > 0
                                  ? () { _saveScrollPosition(); notifier.setChapter(chapterIndex - 1); }
                                  : () {},
                              onNextChapter: chapterIndex < chapters.length - 1
                                  ? () { _saveScrollPosition(); notifier.setChapter(chapterIndex + 1); }
                                  : () {},
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
                                              color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_showTts && !isManga)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: TtsControls(
                                text: chapterContent,
                                onClose: () => setState(() => _showTts = false),
                              ),
                            ),
                          if (showBrightnessOverlay)
                            IgnorePointer(
                              child: Container(
                                color: Color.fromRGBO(0, 0, 0, 1.0 - brightnessValue),
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }

              // Manga page mode: use MangaContentView with PageView
              if (book.contentType == 'manga') {
                final contentAsync = ref.watch(chapterContentProvider((
                  bookId: widget.bookId,
                  chapterIndex: chapterIndex,
                )));

                return contentAsync.when(
                  loading: () => Container(
                    color: bgColor,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Container(
                    color: bgColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 16),
                          Text('加载失败: $e', style: TextStyle(color: textColor)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试'),
                            onPressed: () => ref.invalidate(chapterContentProvider((
                              bookId: widget.bookId,
                              chapterIndex: chapterIndex,
                            ))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (chapterContent) {
                    final imageUrls = _parseImageUrls(chapterContent);
                    final mangaPage = readerState.currentPageIndex.clamp(
                        0, imageUrls.isEmpty ? 0 : imageUrls.length - 1);

                    return GestureDetector(
                      onTapUp: (details) => _handleMangaTap(
                          details, screenSize, notifier),
                      onDoubleTap: () {
                        if (readerState.isLocked) notifier.toggleLock();
                      },
                      child: Stack(
                        children: [
                          MangaContentView(
                            imageUrls: imageUrls,
                            readingMode: 'page',
                            initialPage: mangaPage,
                            backgroundColor: bgColor,
                            onPageChanged: (index) {
                              notifier.setPage(index);
                              notifier.saveProgress(
                                  chapterIndex, index, imageUrls.length);
                            },
                          ),
                          if (readerState.isToolbarVisible)
                            ReaderToolbar(
                              bookTitle: book.title,
                              currentChapter: chapterIndex,
                              totalChapters: chapters.length,
                              isLocked: readerState.isLocked,
                              onBack: () => context.pop(),
                              onToggleLock: notifier.toggleLock,
                              onShowChapters: () => _showChapterDrawer(chapters),
                              onShowSettings: () => _showSettingsPanel(),
                              onShowBookmarks: () =>
                                  _showBookmarkSheet(chapters[chapterIndex]),
                              onToggleNightMode: _toggleNightMode,
                              onChapterChange: (index) {
                                notifier.setChapter(index);
                              },
                              onSwitchSource: book.sourceId != null
                                  ? () => _showSwitchSourceSheet(book)
                                  : null,
                              onPreviousChapter: chapterIndex > 0
                                  ? () => notifier.setChapter(chapterIndex - 1)
                                  : () {},
                              onNextChapter: chapterIndex < chapters.length - 1
                                  ? () => notifier.setChapter(chapterIndex + 1)
                                  : () {},
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
                                              color: Colors.white, fontSize: 12)),
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
              }

              // Page mode: paginated reading with swipe gestures
              final pagesAsync = ref.watch(chapterPagesProvider((
                bookId: widget.bookId,
                chapterIndex: chapterIndex,
                screenWidth: screenSize.width,
                screenHeight: screenSize.height,
              )));

              return pagesAsync.when(
                loading: () => Container(
                  color: bgColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('正在加载章节内容...',
                            style: TextStyle(color: textColor)),
                      ],
                    ),
                  ),
                ),
                error: (e, _) => Container(
                  color: bgColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text('加载失败: $e',
                            style: TextStyle(color: textColor)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                          onPressed: () => ref.invalidate(chapterPagesProvider((
                            bookId: widget.bookId,
                            chapterIndex: chapterIndex,
                            screenWidth: screenSize.width,
                            screenHeight: screenSize.height,
                          ))),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (pages) {
                  if (pages.isEmpty) {
                    return const Center(child: Text('章节内容为空'));
                  }

                  // Restore saved page index on initial load
                  if (!_initialPageRestored) {
                    _initialPageRestored = true;
                    final savedPage = book.lastPageIndex;
                    if (savedPage > 0 && savedPage < pages.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          notifier.setPage(savedPage);
                        }
                      });
                    }
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
                    onHorizontalDragEnd: (details) {
                      if (readerState.isLocked) return;
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -200) {
                        notifier.nextPage(pages.length);
                        _savePageIndex();
                      } else if (velocity > 200) {
                        notifier.previousPage();
                        _savePageIndex();
                      }
                    },
                    child: Stack(
                      children: [
                        _buildBackgroundContainer(
                          bgColor: bgColor,
                          bgImagePath: readingSettings.bgImagePath,
                          child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            switch (readingSettings.pageAnimation) {
                              case 'fade':
                                return FadeTransition(
                                    opacity: animation, child: child);
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
                            backgroundColor: readingSettings.bgImagePath != null &&
                                    readingSettings.bgImagePath!.isNotEmpty
                                ? Colors.transparent
                                : bgColor,
                            fontFamily: readingSettings.fontFamily,
                            fontWeight: readingSettings.fontWeight,
                            firstLineIndent: readingSettings.firstLineIndent,
                            letterSpacing: readingSettings.letterSpacing,
                            eyeProtection: readingSettings.eyeProtection,
                            eyeProtectionIntensity: readingSettings.eyeProtectionIntensity,
                          ),
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
                            onSwitchSource: book.sourceId != null
                                ? () => _showSwitchSourceSheet(book)
                                : null,
                            onPreviousChapter: chapterIndex > 0
                                ? () => notifier.setChapter(chapterIndex - 1)
                                : () {},
                            onNextChapter: chapterIndex < chapters.length - 1
                                ? () => notifier.setChapter(chapterIndex + 1)
                                : () {},
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
                        if (showBrightnessOverlay)
                          IgnorePointer(
                            child: Container(
                              color: Color.fromRGBO(0, 0, 0, 1.0 - brightnessValue),
                              width: double.infinity,
                              height: double.infinity,
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

  Widget _buildBackgroundContainer({
    required Color bgColor,
    required Widget child,
    String? bgImagePath,
  }) {
    if (bgImagePath != null && bgImagePath.isNotEmpty) {
      final file = File(bgImagePath);
      if (file.existsSync()) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
          child: child,
        );
      }
    }
    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      child: child,
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
      _savePageIndex();
    } else if (dx > rightBound) {
      notifier.nextPage(totalPages);
      _savePageIndex();
    } else {
      notifier.toggleToolbar();
    }
  }

  void _savePageIndex() {
    final state = ref.read(readerNotifierProvider(widget.bookId));
    ref.read(bookRepositoryProvider).updateReadingPosition(
      widget.bookId,
      state.currentChapterIndex,
      0.0,
      pageIndex: state.currentPageIndex,
    );
  }

  void _showSwitchSourceSheet(dynamic book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SwitchSourceSheet(
        bookId: book.id,
        bookTitle: book.title,
        currentSourceId: book.sourceId,
      ),
    ).then((switched) {
      if (switched == true) {
        // Refresh chapters after source switch
        ref.invalidate(chaptersProvider(widget.bookId));
        ref.invalidate(chapterContentProvider((
          bookId: widget.bookId,
          chapterIndex: 0,
        )));
      }
    });
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
                    _saveScrollPosition();
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
    final chapters = ref.read(chaptersProvider(widget.bookId)).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BookmarkListSheet(
        bookId: widget.bookId,
        chapters: chapters,
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
    final notifier = ref.read(readingSettingsProvider.notifier);
    notifier.setNightMode(!ref.read(readingSettingsProvider).isNightMode);
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

  List<String> _parseImageUrls(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  void _handleMangaTap(TapUpDetails details, Size screenSize,
      ReaderNotifier notifier) {
    if (ref.read(readerNotifierProvider(widget.bookId)).isLocked) return;

    final dx = details.globalPosition.dx;
    final width = screenSize.width;

    final leftBound = width * 0.3;
    final rightBound = width * 0.7;

    if (dx < leftBound) {
      notifier.previousPage();
    } else if (dx > rightBound) {
      // nextPage with a large count — MangaContentView handles bounds
      notifier.nextPage(9999);
    } else {
      notifier.toggleToolbar();
    }
  }
}
