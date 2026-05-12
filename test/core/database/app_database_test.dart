import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:readlive/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('database can be created and is empty', () async {
    final books = await db.select(db.booksTable).get();
    expect(books, isEmpty);
  });

  test('schema version is 7', () {
    expect(db.schemaVersion, 7);
  });

  test('BookSourcesTable CRUD', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'test-source-1';

    await db.into(db.bookSourcesTable).insert(BookSourcesTableCompanion(
      id: Value(id),
      name: const Value('Test Source'),
      host: const Value('https://example.com'),
      ruleJson: const Value('{"search":{"list":".result"}}'),
      createdAt: Value(now),
    ));

    final sources = await db.select(db.bookSourcesTable).get();
    expect(sources.length, 1);
    expect(sources.first.name, 'Test Source');
    expect(sources.first.enabled, true);

    await (db.delete(db.bookSourcesTable)..where((t) => t.id.equals(id))).go();
    final after = await db.select(db.bookSourcesTable).get();
    expect(after, isEmpty);
  });
}
