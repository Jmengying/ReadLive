import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

class CbzParser {
  static const _uuid = Uuid();
  static final _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};

  Future<BookEntity> importCbzFile(String filePath, BookRepository repo) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('文件不存在: $filePath');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('文件为空: $filePath');
    }

    final isCbr = filePath.toLowerCase().endsWith('.cbr');
    final Archive archive = _decodeArchive(bytes, isCbr);

    // Filter and sort image files
    final imageFiles = <ArchiveFile>[];
    for (final entry in archive) {
      if (entry.isFile) {
        final name = entry.name.toLowerCase();
        final ext = _getExtension(name);
        if (_imageExtensions.contains(ext)) {
          imageFiles.add(entry);
        }
      }
    }

    if (imageFiles.isEmpty) {
      throw Exception('未找到图片文件');
    }

    // Sort by file name for correct page order
    imageFiles.sort((a, b) => a.name.compareTo(b.name));

    // Extract images to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final bookId = _uuid.v4();
    final extractDir = Directory('${appDir.path}/manga/$bookId');
    await extractDir.create(recursive: true);

    final imagePaths = <String>[];
    for (var i = 0; i < imageFiles.length; i++) {
      final fileData = imageFiles[i].content as List<int>;
      final ext = _getExtension(imageFiles[i].name);
      final imagePath = '${extractDir.path}/page_${i.toString().padLeft(4, '0')}$ext';
      await File(imagePath).writeAsBytes(fileData);
      imagePaths.add(imagePath);
    }

    // Use first image as cover
    final coverPath = imagePaths.first;

    // Extract title from file name
    final fileName = filePath.split(Platform.pathSeparator).last;
    final title = fileName.replaceAll(RegExp(r'\.(cbz|cbr)$', caseSensitive: false), '');

    final book = await repo.addBook(
      title: title,
      coverPath: coverPath,
      filePath: filePath,
      contentType: 'manga',
    );

    // Store all image paths as a single chapter
    final now = DateTime.now().millisecondsSinceEpoch;
    final chapterEntry = ChaptersTableCompanion(
      id: Value(_uuid.v4()),
      bookId: Value(book.id),
      title: const Value('全部页面'),
      content: Value(jsonEncode(imagePaths)),
      chapterIndex: const Value(0),
      isCached: const Value(true),
      createdAt: Value(now),
    );

    await repo.insertChapters(book.id, [chapterEntry]);

    // Update book with cover
    await repo.updateCoverPath(book.id, coverPath);

    return await repo.getBookById(book.id) ?? book;
  }

  Archive _decodeArchive(List<int> bytes, bool isCbr) {
    if (isCbr) {
      try {
        return TarDecoder().decodeBytes(bytes);
      } catch (_) {
        return ZipDecoder().decodeBytes(bytes);
      }
    }
    return ZipDecoder().decodeBytes(bytes);
  }

  String _getExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0) return '';
    return name.substring(dotIndex);
  }
}
