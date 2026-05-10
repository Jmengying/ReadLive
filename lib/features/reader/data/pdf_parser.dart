import 'dart:io';
import 'package:drift/drift.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

class PdfParser {
  static const _uuid = Uuid();

  Future<BookEntity> importPdfFile(String filePath, BookRepository repo) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final pageCount = document.pages.count;

    if (pageCount == 0) {
      throw Exception('PDF 文件为空或无法解析');
    }

    // Extract title from file name
    final fileName = filePath.split(Platform.pathSeparator).last;
    final title = fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

    final book = await repo.addBook(
      title: title,
      filePath: filePath,
      contentType: 'novel',
    );

    // Extract text from each page and create chapters
    final now = DateTime.now().millisecondsSinceEpoch;
    final chapterEntries = <ChaptersTableCompanion>[];

    for (var i = 0; i < pageCount; i++) {
      String pageText = '';
      try {
        final extractor = PdfTextExtractor(document);
        pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      } catch (_) {
        // Text extraction failed for this page
      }

      chapterEntries.add(ChaptersTableCompanion(
        id: Value(_uuid.v4()),
        bookId: Value(book.id),
        title: Value('第 ${i + 1} 页'),
        content: Value(pageText.isNotEmpty ? pageText : '[PDF 第 ${i + 1} 页]'),
        chapterIndex: Value(i),
        isCached: const Value(true),
        createdAt: Value(now),
      ));
    }

    await repo.insertChapters(book.id, chapterEntries);
    document.dispose();

    return book;
  }
}
