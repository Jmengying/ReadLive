import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:readlive/core/database/app_database.dart';

/// Get the full file path for a cover image.
/// Handles both absolute paths (legacy) and relative paths (new).
Future<String?> resolveCoverPath(String? coverPath) async {
  if (coverPath == null || coverPath.isEmpty) return null;

  // If it's already an absolute path, return as-is
  if (coverPath.contains('/') || coverPath.contains('\\')) {
    return coverPath;
  }

  // Relative path - construct full path
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/covers/$coverPath';
}

class BookEntity {
  final String id;
  final String title;
  final String? author;
  final String? coverPath;
  final String? filePath;
  final String? sourceId;
  final String? bookUrl;
  final String contentType;
  final String? groupId;
  final int? lastReadAt;
  final double progress; // Chapter scroll position (for restoring reading position)
  final double bookProgress; // Overall book progress (chapters read / total)
  final int lastChapterIndex;
  final double lastScrollOffset;
  final int lastPageIndex;
  final int createdAt;
  final int updatedAt;

  const BookEntity({
    required this.id,
    required this.title,
    this.author,
    this.coverPath,
    this.filePath,
    this.sourceId,
    this.bookUrl,
    required this.contentType,
    this.groupId,
    this.lastReadAt,
    this.progress = 0.0,
    this.bookProgress = 0.0,
    this.lastChapterIndex = 0,
    this.lastScrollOffset = 0.0,
    this.lastPageIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookEntity.fromData(BooksTableData data) {
    return BookEntity(
      id: data.id,
      title: data.title,
      author: data.author,
      coverPath: data.coverPath,
      filePath: data.filePath,
      sourceId: data.sourceId,
      bookUrl: data.bookUrl,
      contentType: data.contentType,
      groupId: data.groupId,
      lastReadAt: data.lastReadAt,
      progress: data.progress,
      bookProgress: data.bookProgress,
      lastChapterIndex: data.lastChapterIndex,
      lastScrollOffset: data.lastScrollOffset,
      lastPageIndex: data.lastPageIndex,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Get the full file path for the cover image.
  /// Handles both absolute paths (legacy) and relative paths (new).
  Future<String?> getFullCoverPath() async {
    if (coverPath == null || coverPath!.isEmpty) return null;

    // If it's already an absolute path, return as-is
    if (coverPath!.contains('/') || coverPath!.contains('\\')) {
      return coverPath;
    }

    // Relative path - construct full path
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/covers/$coverPath';
  }
}
