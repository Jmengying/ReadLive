import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/book_source/presentation/book_source_provider.dart';
import 'package:readlive/features/reader/data/bookmark_repository.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/reader/data/pagination_engine.dart';
import 'package:readlive/features/reader/domain/chapter_entity.dart';
import 'package:readlive/features/reader/domain/page_content.dart';
import 'package:flutter/material.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';

// Current book
final currentBookProvider = FutureProvider.family<BookEntity?, String>((ref, bookId) {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getBookById(bookId);
});

// Chapters for a book
final chaptersProvider = FutureProvider.family<List<ChapterEntity>, String>((ref, bookId) async {
  final db = ref.watch(databaseProvider);
  final data = await db.getChaptersByBook(bookId);
  return data.map((d) => ChapterEntity(
    id: d.id,
    bookId: d.bookId,
    title: d.title,
    url: d.url,
    content: d.content,
    index: d.chapterIndex,
    isCached: d.isCached,
  )).toList();
});

// Reader state
class ReaderState {
  final int currentChapterIndex;
  final int currentPageIndex;
  final bool isToolbarVisible;
  final bool isLocked;
  final double lastScrollOffset;

  const ReaderState({
    this.currentChapterIndex = 0,
    this.currentPageIndex = 0,
    this.isToolbarVisible = false,
    this.isLocked = false,
    this.lastScrollOffset = 0.0,
  });

  ReaderState copyWith({
    int? currentChapterIndex,
    int? currentPageIndex,
    bool? isToolbarVisible,
    bool? isLocked,
    double? lastScrollOffset,
  }) {
    return ReaderState(
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isToolbarVisible: isToolbarVisible ?? this.isToolbarVisible,
      isLocked: isLocked ?? this.isLocked,
      lastScrollOffset: lastScrollOffset ?? this.lastScrollOffset,
    );
  }
}

class ReaderNotifier extends StateNotifier<ReaderState> {
  final BookRepository _repo;
  final String _bookId;

  ReaderNotifier(this._repo, this._bookId) : super(const ReaderState());

  void toggleToolbar() {
    state = state.copyWith(isToolbarVisible: !state.isToolbarVisible);
  }

  void hideToolbar() {
    state = state.copyWith(isToolbarVisible: false);
  }

  void toggleLock() {
    state = state.copyWith(
      isLocked: !state.isLocked,
      isToolbarVisible: false,
    );
  }

  void setChapter(int index) {
    state = state.copyWith(
      currentChapterIndex: index,
      currentPageIndex: 0,
      isToolbarVisible: false,
    );
  }

  void setChapterAndPage(int chapterIndex, int pageIndex) {
    state = state.copyWith(
      currentChapterIndex: chapterIndex,
      currentPageIndex: pageIndex,
      isToolbarVisible: false,
    );
  }

  void nextPage(int totalPages) {
    if (state.currentPageIndex < totalPages - 1) {
      state = state.copyWith(
        currentPageIndex: state.currentPageIndex + 1,
        isToolbarVisible: false,
      );
    }
  }

  void previousPage() {
    if (state.currentPageIndex > 0) {
      state = state.copyWith(
        currentPageIndex: state.currentPageIndex - 1,
        isToolbarVisible: false,
      );
    }
  }

  void setPage(int index) {
    state = state.copyWith(currentPageIndex: index);
  }

  Future<void> saveProgress(int chapterIndex, int pageIndex, int totalPages) async {
    if (totalPages <= 0) return;
    final chapterProgress = pageIndex / totalPages;
    await _repo.updateProgress(_bookId, chapterProgress.clamp(0.0, 1.0));
  }

  Future<void> saveReadingPosition(int chapterIndex, double scrollOffset, {int pageIndex = 0}) async {
    await _repo.updateReadingPosition(_bookId, chapterIndex, scrollOffset, pageIndex: pageIndex);
  }

  void setLastScrollOffset(double offset) {
    state = state.copyWith(lastScrollOffset: offset);
  }
}

final readerNotifierProvider = StateNotifierProvider.family<ReaderNotifier, ReaderState, String>((ref, bookId) {
  final repo = ref.watch(bookRepositoryProvider);
  return ReaderNotifier(repo, bookId);
});

// Fetch and cache a single chapter's content on-demand
final chapterContentProvider = FutureProvider.family<String, ({
  String bookId,
  int chapterIndex,
})>((ref, params) async {
  final chapters = await ref.watch(chaptersProvider(params.bookId).future);
  if (chapters.isEmpty || params.chapterIndex >= chapters.length) return '';

  final chapter = chapters[params.chapterIndex];

  // Already cached
  if (chapter.content != null && chapter.content!.isNotEmpty) {
    return chapter.content!;
  }

  // No URL to fetch from (local book with no content)
  if (chapter.url == null || chapter.url!.isEmpty) return '';

  // Need to fetch from source
  final book = await ref.watch(currentBookProvider(params.bookId).future);
  if (book == null || book.sourceId == null) {
    debugPrint('ChapterContent: book or sourceId is null');
    return '';
  }

  final sourceRepo = ref.watch(bookSourceRepositoryProvider);
  final source = await sourceRepo.getSourceById(book.sourceId!);
  if (source == null) {
    debugPrint('ChapterContent: source not found for id=${book.sourceId}');
    return '';
  }

  final rule = source.parseRule();
  if (rule.content == null) {
    debugPrint('ChapterContent: rule.content is null');
    return '';
  }

  debugPrint('ChapterContent: fetching chapter.url=${chapter.url}, host=${source.host}, content=${rule.content!.content}');

  final crawler = ref.watch(chapterCrawlerProvider);
  final String content;

  if (book.contentType == 'manga') {
    content = await crawler.fetchChapterImages(
      chapterUrl: chapter.url!,
      contentRule: rule.content!,
      host: source.host,
    );
  } else {
    content = await crawler.fetchChapterContent(
      chapterUrl: chapter.url!,
      contentRule: rule.content!,
      host: source.host,
    );
  }

  debugPrint('ChapterContent: result length=${content.length}');

  if (content.isNotEmpty) {
    // Cache to database
    final db = ref.watch(databaseProvider);
    await db.updateChapterContent(chapter.id, content);
    // Invalidate chapters provider so chapter drawer picks up cached status
    ref.invalidate(chaptersProvider(params.bookId));
  }

  return content;
});

// Paginated pages for a chapter
final chapterPagesProvider = FutureProvider.family<List<PageContent>, ({String bookId, int chapterIndex, double screenWidth, double screenHeight})>((ref, params) async {
  final content = await ref.watch(chapterContentProvider((
    bookId: params.bookId,
    chapterIndex: params.chapterIndex,
  )).future);

  if (content.isEmpty) return <PageContent>[];

  // Manga content is a JSON image URL list, not text — skip pagination
  final book = await ref.watch(currentBookProvider(params.bookId).future);
  if (book?.contentType == 'manga') return <PageContent>[];

  final settings = ref.watch(readingSettingsProvider);
  final engine = PaginationEngine(
    fontSize: settings.fontSize,
    lineHeight: settings.lineHeight,
    paragraphSpacing: settings.paragraphSpacing,
    screenWidth: params.screenWidth,
    screenHeight: params.screenHeight,
    padding: const EdgeInsets.all(16),
  );
  return engine.paginate(content);
});

// 书签仓库 Provider
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BookmarkRepository(db);
});

// 书籍的书签列表
final bookmarksProvider =
    FutureProvider.family<List<BookmarksTableData>, String>((ref, bookId) {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return repo.getBookmarks(bookId);
});
