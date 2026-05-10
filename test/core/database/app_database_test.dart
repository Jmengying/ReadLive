import 'package:flutter_test/flutter_test.dart';
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
}
