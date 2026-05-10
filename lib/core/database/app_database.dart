import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [BooksTable, ChaptersTable, BookmarksTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // Books CRUD
  Future<List<BooksTableData>> getAllBooks() => select(booksTable).get();

  Stream<List<BooksTableData>> watchAllBooks() => select(booksTable).watch();

  Future<BooksTableData?> getBookById(String id) =>
      (select(booksTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertBook(BooksTableCompanion entry) =>
      into(booksTable).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateBook(BooksTableCompanion entry) =>
      update(booksTable).replace(entry);

  Future<int> deleteBook(String id) =>
      (delete(booksTable)..where((t) => t.id.equals(id))).go();

  // Chapters CRUD
  Future<List<ChaptersTableData>> getChaptersByBook(String bookId) =>
      (select(chaptersTable)
            ..where((t) => t.bookId.equals(bookId))
            ..orderBy([(t) => OrderingTerm.asc(t.chapterIndex)]))
          .get();

  Stream<List<ChaptersTableData>> watchChaptersByBook(String bookId) =>
      (select(chaptersTable)
            ..where((t) => t.bookId.equals(bookId))
            ..orderBy([(t) => OrderingTerm.asc(t.chapterIndex)]))
          .watch();

  Future<int> insertChapter(ChaptersTableCompanion entry) =>
      into(chaptersTable).insert(entry, mode: InsertMode.insertOrReplace);

  Future<void> insertChapters(List<ChaptersTableCompanion> entries) =>
      batch((batch) => batch.insertAll(chaptersTable, entries,
          mode: InsertMode.insertOrReplace));

  Future<int> deleteChaptersByBook(String bookId) =>
      (delete(chaptersTable)..where((t) => t.bookId.equals(bookId))).go();

  // Bookmarks CRUD
  Future<List<BookmarksTableData>> getBookmarksByBook(String bookId) =>
      (select(bookmarksTable)..where((t) => t.bookId.equals(bookId))).get();

  Future<int> insertBookmark(BookmarksTableCompanion entry) =>
      into(bookmarksTable).insert(entry);

  Future<int> deleteBookmark(String id) =>
      (delete(bookmarksTable)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'readlive.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
