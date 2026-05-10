import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';

class BookmarkRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  BookmarkRepository(this._db);

  Future<List<BookmarksTableData>> getBookmarks(String bookId) =>
      _db.getBookmarksByBook(bookId);

  Future<BookmarksTableData> addBookmark({
    required String bookId,
    required String chapterId,
    required int position,
    String? contentPreview,
    String? note,
    String? highlightColor,
    String type = 'bookmark',
    int? startOffset,
    int? endOffset,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final companion = BookmarksTableCompanion(
      id: Value(id),
      bookId: Value(bookId),
      chapterId: Value(chapterId),
      position: Value(position),
      startOffset: Value(startOffset),
      endOffset: Value(endOffset),
      contentPreview: Value(contentPreview),
      note: Value(note),
      highlightColor: Value(highlightColor),
      type: Value(type),
      createdAt: Value(now),
    );
    await _db.insertBookmark(companion);
    return (await _db.getBookmarksByBook(bookId))
        .firstWhere((b) => b.id == id);
  }

  Future<void> updateBookmarkNote(String bookId, String id, String note) async {
    final bookmarks = await _db.getBookmarksByBook(bookId);
    final existing = bookmarks.firstWhere((b) => b.id == id);
    final companion = BookmarksTableCompanion(
      id: Value(existing.id),
      bookId: Value(existing.bookId),
      chapterId: Value(existing.chapterId),
      position: Value(existing.position),
      contentPreview: Value(existing.contentPreview),
      note: Value(note),
      highlightColor: Value(existing.highlightColor),
      type: Value(note.isNotEmpty ? 'note' : 'bookmark'),
      createdAt: Value(existing.createdAt),
    );
    await _db.updateBookmark(companion);
  }

  Future<void> deleteBookmark(String id) => _db.deleteBookmark(id);

  Future<bool> isBookmarked(String bookId, String chapterId, int position) async {
    final bookmarks = await _db.getBookmarksByBook(bookId);
    return bookmarks.any(
        (b) => b.chapterId == chapterId && b.position == position && b.type == 'bookmark');
  }
}
