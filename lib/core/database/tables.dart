import 'package:drift/drift.dart';

class BooksTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get author => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get bookUrl => text().nullable()();
  TextColumn get contentType => text().withDefault(const Constant('novel'))();
  TextColumn get groupId => text().nullable().references(BookGroupsTable, #id)();
  IntColumn get lastReadAt => integer().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  RealColumn get bookProgress => real().withDefault(const Constant(0.0))();
  IntColumn get lastChapterIndex => integer().withDefault(const Constant(0))();
  RealColumn get lastScrollOffset => real().withDefault(const Constant(0.0))();
  IntColumn get lastPageIndex => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class BookGroupsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChaptersTable extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(BooksTable, #id)();
  TextColumn get title => text()();
  TextColumn get url => text().nullable()();
  TextColumn get content => text().nullable()();
  IntColumn get chapterIndex => integer()();
  BoolColumn get isCached => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class BookSourcesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get host => text()();
  TextColumn get contentType => text().withDefault(const Constant('novel'))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get weight => integer().withDefault(const Constant(100))();
  TextColumn get ruleJson => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get lastTestedAt => integer().nullable()();
  TextColumn get groupName => text().nullable()();
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class BookmarksTable extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(BooksTable, #id)();
  TextColumn get chapterId => text().references(ChaptersTable, #id)();
  IntColumn get position => integer()();
  IntColumn get startOffset => integer().nullable()();
  IntColumn get endOffset => integer().nullable()();
  TextColumn get contentPreview => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get highlightColor => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('bookmark'))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ReadingSessionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(BooksTable, #id)();
  IntColumn get startTime => integer()();
  IntColumn get endTime => integer()();
  IntColumn get durationSeconds => integer()();
  IntColumn get wordsRead => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
