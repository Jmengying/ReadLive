import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';

class DailyReading {
  final DateTime date;
  final int minutes;

  const DailyReading({required this.date, required this.minutes});
}

class BookReadingTime {
  final String bookId;
  final String bookTitle;
  final int totalSeconds;

  const BookReadingTime({
    required this.bookId,
    required this.bookTitle,
    required this.totalSeconds,
  });
}

class ReadingStatsData {
  final List<DailyReading> weeklyData;
  final List<DailyReading> monthlyData;
  final List<BookReadingTime> bookDistribution;
  final int currentStreak;
  final int totalSeconds;
  final int todaySeconds;
  final int totalBooks;

  const ReadingStatsData({
    required this.weeklyData,
    required this.monthlyData,
    required this.bookDistribution,
    required this.currentStreak,
    required this.totalSeconds,
    required this.todaySeconds,
    required this.totalBooks,
  });

  double get avgDailyMinutes {
    if (monthlyData.isEmpty) return 0;
    final total = monthlyData.fold<int>(0, (sum, d) => sum + d.minutes);
    return total / monthlyData.length;
  }
}

final statsProvider = FutureProvider<ReadingStatsData>((ref) async {
  ref.watch(statsRefreshProvider); // re-evaluate when refresh is triggered
  final db = ref.read(databaseProvider);
  final books = await db.getAllBooks();
  final now = DateTime.now();

  // Weekly data (last 7 days)
  final weeklyData = <DailyReading>[];
  for (var i = 6; i >= 0; i--) {
    final date = DateTime(now.year, now.month, now.day - i);
    final startMs = date.millisecondsSinceEpoch;
    final endMs = date.add(const Duration(days: 1)).millisecondsSinceEpoch;
    final sessions = await db.getReadingSessionsByDateRange(startMs, endMs);
    final minutes = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
    weeklyData.add(DailyReading(date: date, minutes: minutes));
  }

  // Monthly data (last 30 days)
  final monthlyData = <DailyReading>[];
  for (var i = 29; i >= 0; i--) {
    final date = DateTime(now.year, now.month, now.day - i);
    final startMs = date.millisecondsSinceEpoch;
    final endMs = date.add(const Duration(days: 1)).millisecondsSinceEpoch;
    final sessions = await db.getReadingSessionsByDateRange(startMs, endMs);
    final minutes = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
    monthlyData.add(DailyReading(date: date, minutes: minutes));
  }

  // Book distribution (top 5 by reading time)
  final bookTimes = <String, int>{};
  final bookTitles = <String, String>{};
  for (final book in books) {
    bookTitles[book.id] = book.title;
    final sessions = await db.getReadingSessionsByBook(book.id);
    final total = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    if (total > 0) bookTimes[book.id] = total;
  }
  final sortedBooks = bookTimes.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final bookDistribution = sortedBooks.take(5).map((e) => BookReadingTime(
    bookId: e.key,
    bookTitle: bookTitles[e.key] ?? '未知',
    totalSeconds: e.value,
  )).toList();

  // Current streak
  var streak = 0;
  for (var i = 0; i < 365; i++) {
    final date = DateTime(now.year, now.month, now.day - i);
    final startMs = date.millisecondsSinceEpoch;
    final endMs = date.add(const Duration(days: 1)).millisecondsSinceEpoch;
    final sessions = await db.getReadingSessionsByDateRange(startMs, endMs);
    if (sessions.isEmpty) break;
    streak++;
  }

  final totalSeconds = await db.getTotalReadingSeconds();
  final todaySeconds = await db.getTodayReadingSeconds();

  return ReadingStatsData(
    weeklyData: weeklyData,
    monthlyData: monthlyData,
    bookDistribution: bookDistribution,
    currentStreak: streak,
    totalSeconds: totalSeconds,
    todaySeconds: todaySeconds,
    totalBooks: books.length,
  );
});
