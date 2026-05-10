import 'dart:io';
import 'package:drift/drift.dart';
import 'package:epubx/epubx.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

class EpubParser {
  static const _uuid = Uuid();

  Future<BookEntity> importEpubFile(
    String filePath,
    BookRepository repo,
  ) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final epub = await EpubReader.readBook(bytes);

    final title = epub.Title ?? filePath.split(Platform.pathSeparator).last;
    final author = epub.Author;

    final book = await repo.addBook(
      title: title,
      author: author,
      filePath: filePath,
      contentType: 'novel',
    );

    // Extract chapters from EPUB, flattening sub-chapters
    final chapters = _flattenChapters(epub.Chapters ?? []);
    final now = DateTime.now().millisecondsSinceEpoch;
    final chapterEntries = <ChaptersTableCompanion>[];

    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterTitle = chapter.Title ?? '第${i + 1}章';
      final content = _extractTextFromHtml(chapter.HtmlContent ?? '');

      chapterEntries.add(ChaptersTableCompanion(
        id: Value(_uuid.v4()),
        bookId: Value(book.id),
        title: Value(chapterTitle),
        content: Value(content),
        chapterIndex: Value(i),
        isCached: const Value(true),
        createdAt: Value(now),
      ));
    }

    if (chapterEntries.isNotEmpty) {
      await repo.insertChapters(book.id, chapterEntries);
    }

    return book;
  }

  /// Recursively flattens the chapter tree into a linear list.
  List<EpubChapter> _flattenChapters(List<EpubChapter> chapters) {
    final result = <EpubChapter>[];
    for (final chapter in chapters) {
      result.add(chapter);
      if (chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty) {
        result.addAll(_flattenChapters(chapter.SubChapters!));
      }
    }
    return result;
  }

  String _extractTextFromHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }
}
