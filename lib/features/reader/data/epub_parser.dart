import 'dart:io';
import 'package:drift/drift.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';
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
    // Build normalized path map for reliable image lookup
    final imagePathMap = _buildImagePathMap(epub, imageDirPath);

    // Extract chapters from EPUB, flattening sub-chapters
    final chapters = _flattenChapters(epub.Chapters ?? []);
    final now = DateTime.now().millisecondsSinceEpoch;
    final chapterEntries = <ChaptersTableCompanion>[];

    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterTitle = chapter.Title ?? '第${i + 1}章';
      final content = _extractTextFromHtml(chapter.HtmlContent ?? '', imageDirPath, imagePathMap: imagePathMap);

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
            coverBytes = _lookupImage(epub.Content!.Images!, href);
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
    // Use openBook + manual chapter reading to work around epubx bug:
    // The library throws "Incorrect EPUB manifest: item with href = X is missing"
    // when NCX navigation uses backslash paths but the content map uses forward slashes.
    // We fix navigation content before reading chapters.
    try {
      return await EpubReader.readBook(bytes);
    } catch (e) {
      if (e.toString().contains('Incorrect EPUB manifest')) {
        return await _readBookWithFixedPaths(bytes);
      }
      rethrow;
    }
  }

  /// Read EPUB by manually fixing backslash paths in navigation content.
  Future<EpubBook> _readBookWithFixedPaths(List<int> bytes) async {
    final bookRef = await EpubReader.openBook(bytes);
    final result = EpubBook();
    result.Schema = bookRef.Schema;
    result.Title = bookRef.Title;
    result.AuthorList = bookRef.AuthorList;
    result.Author = bookRef.Author;

    // Fix backslash paths in navigation points
    _fixNavigationPaths(bookRef.Schema!.Navigation);

    result.Content = await EpubReader.readContent(bookRef.Content!);
    result.CoverImage = await bookRef.readCover();
    var chapterRefs = await bookRef.getChapters();
    result.Chapters = await EpubReader.readChapters(chapterRefs);
    return result;
  }

  /// Recursively normalize backslash paths in navigation content sources.
  void _fixNavigationPaths(dynamic navigation) {
    if (navigation?.NavMap?.Points != null) {
      _fixNavigationPoints(navigation.NavMap.Points);
    }
  }

  void _fixNavigationPoints(List<dynamic> points) {
    for (final point in points) {
      if (point.Content?.Source != null) {
        point.Content.Source = point.Content.Source.replaceAll(r'\', '/');
      }
      if (point.ChildNavigationPoints != null) {
        _fixNavigationPoints(point.ChildNavigationPoints);
      }
    }
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

  /// Build a map from normalized image paths to actual saved file paths.
  /// This handles the mismatch between epubx library keys and HTML img src paths.
  Map<String, String> _buildImagePathMap(EpubBook epub, String imageDirPath) {
    final map = <String, String>{};
    if (epub.Content?.Images == null) return map;

    for (final entry in epub.Content!.Images!.entries) {
      final key = entry.key;
      final safeName = key.replaceAll('/', '_').replaceAll('\\', '_');
      final fullPath = '$imageDirPath/$safeName';

      // Register multiple normalized forms for lookup
      map[_normalizePath(key)] = fullPath;

      // Also register without OEBPS prefix
      final lower = key.toLowerCase();
      if (lower.startsWith('oebps/')) {
        map[_normalizePath(key.substring(6))] = fullPath;
      }
    }
    return map;
  }

  /// Normalize a path for consistent lookup (lowercase, forward slashes, no leading ./ or /).
  String _normalizePath(String path) {
    var p = path.replaceAll('\\', '/').toLowerCase();
    while (p.startsWith('./')) p = p.substring(2);
    while (p.startsWith('/')) p = p.substring(1);
    // Remove OEBPS/ prefix if present
    if (p.startsWith('oebps/')) p = p.substring(6);
    return p;
  }

  String _extractTextFromHtml(
    String html,
    String imageDirPath, {
    Map<String, String>? imagePathMap,
  }) {
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
          final placeholder = _resolveImagePlaceholder(src, imageDirPath, imagePathMap);
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

  /// Resolve an img src to an [[IMG:...]] placeholder, using the path map for reliable lookup.
  String _resolveImagePlaceholder(
    String src,
    String imageDirPath,
    Map<String, String>? imagePathMap,
  ) {
    // 1. Try direct lookup via normalized path map
    if (imagePathMap != null) {
      final normalized = _normalizePath(_resolveRelativePath(src));
      final match = imagePathMap[normalized];
      if (match != null) return '[[IMG:$match]]';
    }

    // 2. Fallback: flatten path and check if file exists
    final resolved = _resolveRelativePath(src);
    final safeName = resolved.replaceAll('/', '_').replaceAll('\\', '_');
    final directPath = '$imageDirPath/$safeName';
    if (File(directPath).existsSync()) return '[[IMG:$directPath]]';

    // 3. Last resort: scan image directory for matching filename
    if (imagePathMap != null) {
      final srcLower = src.toLowerCase().replaceAll('\\', '/');
      final filename = srcLower.split('/').last;
      for (final entry in imagePathMap.entries) {
        if (entry.key.endsWith('/$filename') || entry.key == filename) {
          return '[[IMG:${entry.value}]]';
        }
      }
    }

    return '';
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

  /// Look up an image in the epub image map, trying multiple path variations.
  List<int>? _lookupImage(Map<String, EpubByteContentFile> images, String href) {
    final normalized = href.replaceAll('\\', '/');

    // Try direct match
    final direct = images[href]?.Content;
    if (direct != null) return direct;

    // Try normalized path
    if (normalized != href) {
      final norm = images[normalized]?.Content;
      if (norm != null) return norm;
    }

    // Try case-insensitive match
    final hrefLower = normalized.toLowerCase();
    for (final entry in images.entries) {
      if (entry.key.replaceAll('\\', '/').toLowerCase() == hrefLower) {
        return entry.value.Content;
      }
    }

    // Try without OEBPS/ prefix
    if (hrefLower.startsWith('oebps/')) {
      final withoutPrefix = hrefLower.substring(6);
      for (final entry in images.entries) {
        if (entry.key.replaceAll('\\', '/').toLowerCase() == withoutPrefix) {
          return entry.value.Content;
        }
      }
    }

    // Try filename-only match as last resort
    final filename = hrefLower.split('/').last;
    for (final entry in images.entries) {
      if (entry.key.toLowerCase().endsWith('/$filename')) {
        return entry.value.Content;
      }
    }

    return null;
  }
}
