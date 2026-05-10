import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';
import 'package:readlive/features/reader/domain/chapter_entity.dart';

class TxtParser {
  static const _uuid = Uuid();
  static final _chapterPattern = RegExp(
    r'^第[零一二三四五六七八九十百千万\d]+[章节回卷集部篇].*$',
    multiLine: true,
  );

  List<ParsedChapter> splitChapters(String text) {
    final matches = _chapterPattern.allMatches(text).toList();

    if (matches.isEmpty) {
      return [ParsedChapter(title: '开始', content: text.trim())];
    }

    final chapters = <ParsedChapter>[];

    // Content before first chapter
    final preamble = text.substring(0, matches.first.start).trim();
    if (preamble.isNotEmpty) {
      chapters.add(ParsedChapter(title: '序章', content: preamble));
    }

    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final block = text.substring(start, end).trim();

      // Extract title from first line
      final newlineIndex = block.indexOf('\n');
      final title = newlineIndex > 0
          ? block.substring(0, newlineIndex).trim()
          : block.trim();
      final content = newlineIndex > 0
          ? block.substring(newlineIndex + 1).trim()
          : '';

      chapters.add(ParsedChapter(title: title, content: content));
    }

    return chapters;
  }

  Future<BookEntity> importTxtFile(String filePath, BookRepository repo) async {
    final file = File(filePath);
    final text = await file.readAsString();
    final fileName = filePath.split(Platform.pathSeparator).last;
    final title = fileName.replaceAll(RegExp(r'\.txt$', caseSensitive: false), '');

    final book = await repo.addBook(
      title: title,
      filePath: filePath,
      contentType: 'novel',
    );

    final parsedChapters = splitChapters(text);
    final now = DateTime.now().millisecondsSinceEpoch;

    final chapterEntries = <ChaptersTableCompanion>[];
    for (var i = 0; i < parsedChapters.length; i++) {
      final ch = parsedChapters[i];
      chapterEntries.add(ChaptersTableCompanion(
        id: Value(_uuid.v4()),
        bookId: Value(book.id),
        title: Value(ch.title),
        content: Value(ch.content),
        chapterIndex: Value(i),
        isCached: const Value(true),
        createdAt: Value(now),
      ));
    }

    await repo.insertChapters(book.id, chapterEntries);
    return book;
  }
}
