class ChapterEntity {
  final String id;
  final String bookId;
  final String title;
  final String? url;
  final String? content;
  final int index;
  final bool isCached;

  const ChapterEntity({
    required this.id,
    required this.bookId,
    required this.title,
    this.url,
    this.content,
    required this.index,
    this.isCached = false,
  });
}

class ParsedChapter {
  final String title;
  final String content;

  const ParsedChapter({required this.title, required this.content});
}
