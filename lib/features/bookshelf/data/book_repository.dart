import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

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

  Future<void> insertChapters(
    String bookId,
    List<ChaptersTableCompanion> chapters,
  ) async {
    await _db.deleteChaptersByBook(bookId);
    await _db.insertChapters(chapters);
  }
}
