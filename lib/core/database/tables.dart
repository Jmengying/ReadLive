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
  IntColumn get lastReadAt => integer().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

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

class BookmarksTable extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(BooksTable, #id)();
  TextColumn get chapterId => text().references(ChaptersTable, #id)();
  IntColumn get position => integer()();
  TextColumn get contentPreview => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get highlightColor => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('bookmark'))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
