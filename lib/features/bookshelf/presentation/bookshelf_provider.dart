import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/bookshelf/data/book_group_repository.dart';
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

final bookGroupRepositoryProvider = Provider<BookGroupRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BookGroupRepository(db);
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

// Group-filtered books provider
final groupFilteredBooksProvider =
    Provider.family<AsyncValue<List<BookEntity>>, ({String contentType, String? groupId})>((ref, params) {
  final booksAsync = ref.watch(filteredBooksProvider(params.contentType));
  return booksAsync.whenData(
    (books) {
      if (params.groupId == null) return books;
      if (params.groupId == '__ungrouped') {
        return books.where((b) => b.groupId == null).toList();
      }
      return books.where((b) => b.groupId == params.groupId).toList();
    },
  );
});

// Book groups stream
final bookGroupsProvider = StreamProvider<List<BookGroupsTableData>>((ref) {
  final repo = ref.watch(bookGroupRepositoryProvider);
  return repo.watchAllGroups();
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

// Stats refresh trigger — invalidate this to force stats reload
final statsRefreshProvider = StateProvider<int>((ref) => 0);

// Reading stats
final readingStatsProvider = FutureProvider<ReadingStats>((ref) async {
  ref.watch(statsRefreshProvider); // re-evaluate when refresh is triggered
  final db = ref.read(databaseProvider);
  final totalSeconds = await db.getTotalReadingSeconds();
  final todaySeconds = await db.getTodayReadingSeconds();
  final todayWords = await db.getTodayWordsRead();
  return ReadingStats(
    totalSeconds: totalSeconds,
    todaySeconds: todaySeconds,
    todayWords: todayWords,
  );
});

class ReadingStats {
  final int totalSeconds;
  final int todaySeconds;
  final int todayWords;

  const ReadingStats({
    required this.totalSeconds,
    required this.todaySeconds,
    required this.todayWords,
  });

  String get totalFormatted {
    if (totalSeconds < 60) return '$totalSeconds 秒';
    if (totalSeconds < 3600) return '${totalSeconds ~/ 60} 分钟';
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    return m > 0 ? '$h 小时 $m 分钟' : '$h 小时';
  }

  String get todayFormatted {
    if (todaySeconds < 60) return '$todaySeconds 秒';
    if (todaySeconds < 3600) return '${todaySeconds ~/ 60} 分钟';
    final h = todaySeconds ~/ 3600;
    final m = (todaySeconds % 3600) ~/ 60;
    return m > 0 ? '$h 小时 $m 分钟' : '$h 小时';
  }

  String get todayWordsFormatted {
    if (todayWords < 1000) return '$todayWords字';
    if (todayWords < 10000) return '${(todayWords / 1000).toStringAsFixed(1)}千字';
    return '${(todayWords / 10000).toStringAsFixed(1)}万字';
  }
}
