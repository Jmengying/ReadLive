import 'dart:io';
import 'package:drift/drift.dart';
import 'package:epubx/epubx.dart';
import 'package:path_provider/path_provider.dart';
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
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('文件为空: $filePath');
    }

    final epub = await _readBookSafe(bytes);

    final title = epub.Title ?? filePath.split(Platform.pathSeparator).last;
    final author = epub.Author;

    // Extract and save cover image
    final coverPath = await _saveCoverImage(epub);

    final book = await repo.addBook(
      title: title,
      author: author,
      coverPath: coverPath,
      filePath: filePath,
      contentType: 'novel',
    );

    // Save all chapter images to local directory
    final imageDirPath = await _saveChapterImages(epub, book.id);

    // Extract chapters from EPUB, flattening sub-chapters
    final chapters = _flattenChapters(epub.Chapters ?? []);
    final now = DateTime.now().millisecondsSinceEpoch;
    final chapterEntries = <ChaptersTableCompanion>[];

    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterTitle = chapter.Title ?? '第${i + 1}章';
      final content = _extractTextFromHtml(chapter.HtmlContent ?? '', imageDirPath);

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

  Future<String?> _saveCoverImage(EpubBook epub) async {
    try {
      List<int>? coverBytes;

      // Method 1: Find cover by manifest metadata
      if (epub.Schema?.Package?.Metadata?.MetaItems != null) {
        final metaItems = epub.Schema!.Package!.Metadata!.MetaItems;
        final coverMeta = metaItems?.where(
          (m) => m.Name?.toLowerCase() == 'cover',
        ).firstOrNull;
        if (coverMeta?.Content != null) {
          final coverId = coverMeta!.Content!.toLowerCase();
          final manifestItem = epub.Schema!.Package!.Manifest!.Items?.where(
            (item) => item.Id?.toLowerCase() == coverId,
          ).firstOrNull;
          if (manifestItem?.Href != null && epub.Content?.Images != null) {
            final href = manifestItem!.Href!;
            final normalizedHref = href.replaceAll('\\', '/');
            coverBytes = epub.Content!.Images![href]?.Content ??
                epub.Content!.Images![normalizedHref]?.Content;
          }
        }
      }

      // Method 2: Find any image with "cover" in the name
      if (coverBytes == null && epub.Content?.Images != null) {
        for (final entry in epub.Content!.Images!.entries) {
          if (entry.key.toLowerCase().contains('cover')) {
            coverBytes = entry.value.Content;
            break;
          }
        }
      }

      if (coverBytes == null || coverBytes.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${dir.path}/covers');
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }
      final file = File('${coverDir.path}/${_uuid.v4()}.png');
      await file.writeAsBytes(coverBytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<String> _saveChapterImages(EpubBook epub, String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${dir.path}/book_images/$bookId');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    if (epub.Content?.Images != null) {
      for (final entry in epub.Content!.Images!.entries) {
        final bytes = entry.value.Content;
        final safeName = entry.key.replaceAll('/', '_').replaceAll('\\', '_');
        if (bytes != null && bytes.isNotEmpty) {
          final file = File('${imageDir.path}/$safeName');
          await file.writeAsBytes(bytes);
        }
      }
    }
    return imageDir.path;
  }

  Future<EpubBook> _readBookSafe(List<int> bytes) async {
    return await EpubReader.readBook(bytes);
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

  String _extractTextFromHtml(String html, String imageDirPath) {
    final imgTagPattern = RegExp(r'<img\b[^>]*>', caseSensitive: false);
    final srcPattern = RegExp(r'''src\s*=\s*["']([^"']+)["']''', caseSensitive: false);

    var result = html;

    // Strip blocks that should not appear as text
    result = result.replaceAll(RegExp(r'<script\b[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');
    result = result.replaceAll(RegExp(r'<style\b[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '');
    result = result.replaceAll(RegExp(r'<head\b[^>]*>.*?</head>', caseSensitive: false, dotAll: true), '');
    result = result.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

    for (final imgMatch in imgTagPattern.allMatches(result)) {
      final imgTag = imgMatch.group(0) ?? '';
      final srcMatch = srcPattern.firstMatch(imgTag);
      if (srcMatch != null) {
        final src = srcMatch.group(1) ?? '';
        if (src.isNotEmpty) {
          // Resolve relative paths: strip leading ../ segments
          final normalized = _resolveRelativePath(src);
          final safeName = normalized.replaceAll('/', '_').replaceAll('\\', '_');
          final placeholder = '[[IMG:$imageDirPath/$safeName]]';
          result = result.replaceAll(imgTag, '\n$placeholder\n');
        } else {
          result = result.replaceAll(imgTag, '');
        }
      } else {
        result = result.replaceAll(imgTag, '');
      }
    }

    return result
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }

  /// Resolve relative path by stripping leading ../ segments.
  /// EPUB images are stored by their path within the EPUB archive,
  /// but chapter HTML may reference them with relative paths like ../images/xxx.jpg.
  String _resolveRelativePath(String src) {
    var path = src.replaceAll('\\', '/');
    // Remove leading ../ segments
    while (path.startsWith('../')) {
      path = path.substring(3);
    }
    // Remove leading ./ segments
    while (path.startsWith('./')) {
      path = path.substring(2);
    }
    return path;
  }
}
