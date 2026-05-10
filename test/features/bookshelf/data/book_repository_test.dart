import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';

void main() {
  late AppDatabase db;
  late BookRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = BookRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addBook and getAllBooks', () async {
    final book = await repo.addBook(
      title: 'Test Book',
      author: 'Author',
      filePath: '/path/to/file.txt',
      contentType: 'novel',
    );
    expect(book.title, 'Test Book');

    final books = await repo.getAllBooks();
    expect(books.length, 1);
    expect(books.first.title, 'Test Book');
  });

  test('deleteBook removes book and its chapters', () async {
    final book = await repo.addBook(
      title: 'To Delete',
      filePath: '/path.txt',
      contentType: 'novel',
    );
    await repo.deleteBook(book.id);
    final books = await repo.getAllBooks();
    expect(books, isEmpty);
  });

  test('updateProgress', () async {
    final book = await repo.addBook(
      title: 'Progress Book',
      filePath: '/path.txt',
      contentType: 'novel',
    );
    await repo.updateProgress(book.id, 0.5);
    final updated = await repo.getBookById(book.id);
    expect(updated!.progress, 0.5);
  });
}
