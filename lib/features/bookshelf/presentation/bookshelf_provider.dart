import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BookRepository(db);
});

final booksStreamProvider = StreamProvider<List<BookEntity>>((ref) {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.watchAllBooks();
});

final filteredBooksProvider =
    Provider.family<AsyncValue<List<BookEntity>>, String>((ref, contentType) {
  final booksAsync = ref.watch(booksStreamProvider);
  return booksAsync.whenData(
    (books) => books.where((b) => b.contentType == contentType).toList(),
  );
});

class BookshelfActions {
  final BookRepository _repo;
  BookshelfActions(this._repo);

  Future<void> deleteBook(String id) => _repo.deleteBook(id);
  Future<void> updateProgress(String id, double progress) =>
      _repo.updateProgress(id, progress);
}

final bookshelfActionsProvider = Provider<BookshelfActions>((ref) {
  final repo = ref.watch(bookRepositoryProvider);
  return BookshelfActions(repo);
});
