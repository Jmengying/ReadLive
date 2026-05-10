import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/reader/data/pagination_engine.dart';
import 'package:readlive/features/reader/domain/chapter_entity.dart';
import 'package:readlive/features/reader/domain/page_content.dart';
import 'package:flutter/material.dart';

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

  const ReaderState({
    this.currentChapterIndex = 0,
    this.currentPageIndex = 0,
    this.isToolbarVisible = false,
    this.isLocked = false,
  });

  ReaderState copyWith({
    int? currentChapterIndex,
    int? currentPageIndex,
    bool? isToolbarVisible,
    bool? isLocked,
  }) {
    return ReaderState(
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isToolbarVisible: isToolbarVisible ?? this.isToolbarVisible,
      isLocked: isLocked ?? this.isLocked,
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
    state = state.copyWith(isLocked: !state.isLocked);
  }

  void setChapter(int index) {
    state = state.copyWith(
      currentChapterIndex: index,
      currentPageIndex: 0,
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
}

final readerNotifierProvider = StateNotifierProvider.family<ReaderNotifier, ReaderState, String>((ref, bookId) {
  final repo = ref.watch(bookRepositoryProvider);
  return ReaderNotifier(repo, bookId);
});

// Paginated pages for a chapter
final chapterPagesProvider = FutureProvider.family<List<PageContent>, ({String bookId, int chapterIndex, double screenWidth, double screenHeight})>((ref, params) async {
  final chapters = await ref.watch(chaptersProvider(params.bookId).future);
  if (chapters.isEmpty || params.chapterIndex >= chapters.length) {
    return <PageContent>[];
  }
  final content = chapters[params.chapterIndex].content ?? '';
  final engine = PaginationEngine(
    fontSize: 18,
    lineHeight: 1.8,
    paragraphSpacing: 16,
    screenWidth: params.screenWidth,
    screenHeight: params.screenHeight,
    padding: const EdgeInsets.all(16),
  );
  return engine.paginate(content);
});
