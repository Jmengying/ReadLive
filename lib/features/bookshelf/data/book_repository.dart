import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';

class BookRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  BookRepository(this._db);

  Future<List<BookEntity>> getAllBooks() async {
    final data = await _db.getAllBooks();
    return data.map(BookEntity.fromData).toList();
  }

  Stream<List<BookEntity>> watchAllBooks() {
    return _db.watchAllBooks().map(
          (list) => list.map(BookEntity.fromData).toList(),
        );
  }

  Future<BookEntity?> getBookById(String id) async {
    final data = await _db.getBookById(id);
    return data != null ? BookEntity.fromData(data) : null;
  }

  Future<BookEntity> addBook({
    required String title,
    String? author,
    String? coverPath,
    String? filePath,
    String? sourceId,
    String? bookUrl,
    required String contentType,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final companion = BooksTableCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      coverPath: Value(coverPath),
      filePath: Value(filePath),
      sourceId: Value(sourceId),
      bookUrl: Value(bookUrl),
      contentType: Value(contentType),
      progress: const Value(0.0),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await _db.insertBook(companion);
    return (await getBookById(id))!;
  }

  Future<void> deleteBook(String id) async {
    await _db.deleteChaptersByBook(id);
    await _db.deleteBook(id);
  }

  Future<void> updateProgress(String bookId, double progress) async {
    final book = await _db.getBookById(bookId);
    if (book == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = book.toCompanion(true).copyWith(
          progress: Value(progress),
          lastReadAt: Value(now),
          updatedAt: Value(now),
        );
    await _db.updateBook(companion);
  }

  Future<void> updateBookProgress(String bookId, double bookProgress) async {
    final book = await _db.getBookById(bookId);
    if (book == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = book.toCompanion(true).copyWith(
          bookProgress: Value(bookProgress),
          lastReadAt: Value(now),
          updatedAt: Value(now),
        );
    await _db.updateBook(companion);
  }

  Future<void> updateReadingPosition(
    String bookId,
    int chapterIndex,
    double scrollOffset, {
    int pageIndex = 0,
    double progress = 0.0,
  }) async {
    final book = await _db.getBookById(bookId);
    if (book == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = book.toCompanion(true).copyWith(
          lastChapterIndex: Value(chapterIndex),
          lastScrollOffset: Value(scrollOffset),
          lastPageIndex: Value(pageIndex),
          progress: Value(progress),
          lastReadAt: Value(now),
          updatedAt: Value(now),
        );
    await _db.updateBook(companion);
  }

  Future<void> updateCoverPath(String bookId, String coverPath) async {
    final book = await _db.getBookById(bookId);
    if (book == null) return;
    final companion = book.toCompanion(true).copyWith(
          coverPath: Value(coverPath),
        );
    await _db.updateBook(companion);
  }

  Future<void> insertChapters(
    String bookId,
    List<ChaptersTableCompanion> chapters,
  ) async {
    await _db.deleteChaptersByBook(bookId);
    await _db.insertChapters(chapters);
  }

  Future<void> updateChapterContent(String chapterId, String content) async {
    await _db.updateChapterContent(chapterId, content);
  }

  Future<void> switchSource(
    String bookId,
    String newSourceId,
    String newBookUrl,
    List<TocEntry> newChapters,
  ) async {
    final book = await _db.getBookById(bookId);
    if (book == null) return;

    // Update book's source info
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = book.toCompanion(true).copyWith(
      sourceId: Value(newSourceId),
      bookUrl: Value(newBookUrl),
      updatedAt: Value(now),
    );
    await _db.updateBook(companion);

    // Replace chapters
    await _db.deleteChaptersByBook(bookId);
    final uuid = const Uuid();
    final chapterCompanions = <ChaptersTableCompanion>[];
    for (var i = 0; i < newChapters.length; i++) {
      chapterCompanions.add(ChaptersTableCompanion(
        id: Value(uuid.v4()),
        bookId: Value(bookId),
        title: Value(newChapters[i].title),
        url: Value(newChapters[i].url),
        content: const Value(null),
        chapterIndex: Value(i),
        isCached: const Value(false),
        createdAt: Value(now),
      ));
    }
    await _db.insertChapters(chapterCompanions);
  }
}
