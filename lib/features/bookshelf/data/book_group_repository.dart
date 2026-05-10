import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';

class BookGroupRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  BookGroupRepository(this._db);

  Future<List<BookGroupsTableData>> getAllGroups() => _db.getAllBookGroups();

  Stream<List<BookGroupsTableData>> watchAllGroups() => _db.watchAllBookGroups();

  Future<BookGroupsTableData> addGroup(String name) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final companion = BookGroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(now),
    );
    await _db.insertBookGroup(companion);
    return (await _db.getAllBookGroups()).firstWhere((g) => g.id == id);
  }

  Future<void> renameGroup(String id, String newName) async {
    final groups = await _db.getAllBookGroups();
    final existing = groups.firstWhere((g) => g.id == id);
    final companion = existing.toCompanion(true).copyWith(name: Value(newName));
    await _db.updateBookGroup(companion);
  }

  Future<void> deleteGroup(String id) async {
    // Unassign all books in this group first
    final books = await _db.getBooksByGroup(id);
    for (final book in books) {
      final companion = book.toCompanion(true).copyWith(groupId: const Value(null));
      await _db.updateBook(companion);
    }
    await _db.deleteBookGroup(id);
  }

  Future<void> moveBooksToGroup(List<String> bookIds, String? groupId) =>
      _db.batchSetGroup(bookIds, groupId);

  Future<void> batchDeleteBooks(List<String> bookIds) async {
    for (final id in bookIds) {
      await _db.deleteChaptersByBook(id);
      await _db.deleteBook(id);
    }
  }
}
