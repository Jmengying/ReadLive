import 'package:readlive/core/database/app_database.dart';

class BookEntity {
  final String id;
  final String title;
  final String? author;
  final String? coverPath;
  final String? filePath;
  final String? sourceId;
  final String? bookUrl;
  final String contentType;
  final int? lastReadAt;
  final double progress;
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
    this.lastReadAt,
    this.progress = 0.0,
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
      lastReadAt: data.lastReadAt,
      progress: data.progress,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }
}
