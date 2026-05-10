class SearchResult {
  final String bookName;
  final String? author;
  final String? cover;
  final String? intro;
  final String bookUrl;
  final String sourceId;
  final String sourceName;

  const SearchResult({
    required this.bookName,
    this.author,
    this.cover,
    this.intro,
    required this.bookUrl,
    required this.sourceId,
    required this.sourceName,
  });
}
