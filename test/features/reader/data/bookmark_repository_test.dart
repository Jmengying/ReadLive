import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/reader/data/bookmark_repository.dart';

void main() {
  late AppDatabase db;
  late BookRepository bookRepo;
  late BookmarkRepository bookmarkRepo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    bookRepo = BookRepository(db);
    bookmarkRepo = BookmarkRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addBookmark and getBookmarks', () async {
    final book = await bookRepo.addBook(
      title: 'Test',
      filePath: '/test.txt',
      contentType: 'novel',
    );

    final bm = await bookmarkRepo.addBookmark(
      bookId: book.id,
      chapterId: 'ch-1',
      position: 42,
      contentPreview: 'Test bookmark',
    );

    expect(bm.bookId, book.id);
    expect(bm.position, 42);

    final bookmarks = await bookmarkRepo.getBookmarks(book.id);
    expect(bookmarks.length, 1);
    expect(bookmarks.first.contentPreview, 'Test bookmark');
  });

  test('deleteBookmark', () async {
    final book = await bookRepo.addBook(
      title: 'Test',
      filePath: '/test.txt',
      contentType: 'novel',
    );

    final bm = await bookmarkRepo.addBookmark(
      bookId: book.id,
      chapterId: 'ch-1',
      position: 0,
    );

    await bookmarkRepo.deleteBookmark(bm.id);
    final bookmarks = await bookmarkRepo.getBookmarks(book.id);
    expect(bookmarks, isEmpty);
  });

  test('isBookmarked', () async {
    final book = await bookRepo.addBook(
      title: 'Test',
      filePath: '/test.txt',
      contentType: 'novel',
    );

    expect(await bookmarkRepo.isBookmarked(book.id, 'ch-1', 42), false);

    await bookmarkRepo.addBookmark(
      bookId: book.id,
      chapterId: 'ch-1',
      position: 42,
    );

    expect(await bookmarkRepo.isBookmarked(book.id, 'ch-1', 42), true);
    expect(await bookmarkRepo.isBookmarked(book.id, 'ch-1', 43), false);
  });
}
