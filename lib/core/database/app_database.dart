import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [BooksTable, ChaptersTable, BookmarksTable, BookSourcesTable, BookGroupsTable, ReadingSessionsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(bookSourcesTable);
          }
          if (from < 3) {
            await m.createTable(bookGroupsTable);
            await m.createTable(readingSessionsTable);
            await m.addColumn(booksTable, booksTable.groupId);
          }
          if (from < 4) {
            await m.addColumn(bookmarksTable, bookmarksTable.startOffset);
            await m.addColumn(bookmarksTable, bookmarksTable.endOffset);
          }
          if (from < 5) {
            await m.addColumn(bookSourcesTable, bookSourcesTable.builtIn);
          }
        },
      );

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

  Future<void> updateChapterContent(String chapterId, String content) async {
    await (update(chaptersTable)..where((t) => t.id.equals(chapterId)))
        .write(ChaptersTableCompanion(
      content: Value(content),
      isCached: const Value(true),
    ));
  }

  // Bookmarks CRUD
  Future<List<BookmarksTableData>> getBookmarksByBook(String bookId) =>
      (select(bookmarksTable)..where((t) => t.bookId.equals(bookId))).get();

  Future<int> insertBookmark(BookmarksTableCompanion entry) =>
      into(bookmarksTable).insert(entry);

  Future<bool> updateBookmark(BookmarksTableCompanion entry) =>
      update(bookmarksTable).replace(entry);

  Future<int> deleteBookmark(String id) =>
      (delete(bookmarksTable)..where((t) => t.id.equals(id))).go();

  // Book Groups CRUD
  Future<List<BookGroupsTableData>> getAllBookGroups() =>
      (select(bookGroupsTable)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Stream<List<BookGroupsTableData>> watchAllBookGroups() =>
      (select(bookGroupsTable)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<int> insertBookGroup(BookGroupsTableCompanion entry) =>
      into(bookGroupsTable).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateBookGroup(BookGroupsTableCompanion entry) =>
      update(bookGroupsTable).replace(entry);

  Future<int> deleteBookGroup(String id) =>
      (delete(bookGroupsTable)..where((t) => t.id.equals(id))).go();

  Future<List<BooksTableData>> getBooksByGroup(String groupId) =>
      (select(booksTable)..where((t) => t.groupId.equals(groupId))).get();

  Future<List<BooksTableData>> getUngroupedBooks() =>
      (select(booksTable)..where((t) => t.groupId.isNull())).get();

  Future<void> batchDeleteBooks(List<String> ids) async {
    for (final id in ids) {
      await (delete(booksTable)..where((t) => t.id.equals(id))).go();
    }
  }

  Future<void> batchSetGroup(List<String> bookIds, String? groupId) async {
    for (final id in bookIds) {
      final book = await getBookById(id);
      if (book != null) {
        final companion = book.toCompanion(true).copyWith(
          groupId: Value(groupId),
        );
        await updateBook(companion);
      }
    }
  }

  // Reading Sessions CRUD
  Future<int> insertReadingSession(ReadingSessionsTableCompanion entry) =>
      into(readingSessionsTable).insert(entry);

  Future<List<ReadingSessionsTableData>> getReadingSessionsByBook(String bookId) =>
      (select(readingSessionsTable)..where((t) => t.bookId.equals(bookId))).get();

  Future<List<ReadingSessionsTableData>> getReadingSessionsByDateRange(
      int startMs, int endMs) =>
      (select(readingSessionsTable)
            ..where((t) => t.startTime.isBiggerOrEqualValue(startMs) & t.startTime.isSmallerOrEqualValue(endMs)))
          .get();

  Future<int> getTotalReadingSeconds() async {
    final sessions = await select(readingSessionsTable).get();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  Future<int> getTodayReadingSeconds() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final sessions = await (select(readingSessionsTable)
          ..where((t) => t.startTime.isBiggerOrEqualValue(todayStart)))
        .get();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  Future<int> getTodayWordsRead() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final sessions = await (select(readingSessionsTable)
          ..where((t) => t.startTime.isBiggerOrEqualValue(todayStart)))
        .get();
    return sessions.fold<int>(0, (sum, s) => sum + s.wordsRead);
  }

  // Book Sources CRUD
  Future<List<BookSourcesTableData>> getAllBookSources() =>
      select(bookSourcesTable).get();

  Stream<List<BookSourcesTableData>> watchAllBookSources() =>
      select(bookSourcesTable).watch();

  Future<BookSourcesTableData?> getBookSourceById(String id) =>
      (select(bookSourcesTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<BookSourcesTableData>> getEnabledBookSources() =>
      (select(bookSourcesTable)..where((t) => t.enabled.equals(true))).get();

  Future<int> insertBookSource(BookSourcesTableCompanion entry) =>
      into(bookSourcesTable).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateBookSource(BookSourcesTableCompanion entry) =>
      update(bookSourcesTable).replace(entry);

  Future<int> deleteBookSource(String id) =>
      (delete(bookSourcesTable)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'readlive.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
