import 'dart:convert';

class SourceRule {
  final String? id;
  final String name;
  final String host;
  final String contentType;
  final bool enabled;
  final int weight;
  final SearchRule? search;
  final BookInfoRule? bookInfo;
  final TocRule? toc;
  final ContentRule? content;

  const SourceRule({
    this.id,
    required this.name,
    required this.host,
    this.contentType = 'novel',
    this.enabled = true,
    this.weight = 100,
    this.search,
    this.bookInfo,
    this.toc,
    this.content,
  });

  factory SourceRule.fromJson(Map<String, dynamic> json) {
    return SourceRule(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      host: json['host'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'novel',
      enabled: json['enabled'] as bool? ?? true,
      weight: json['weight'] as int? ?? 100,
      search: json['search'] != null
          ? SearchRule.fromJson(json['search'] as Map<String, dynamic>)
          : null,
      bookInfo: json['bookInfo'] != null
          ? BookInfoRule.fromJson(json['bookInfo'] as Map<String, dynamic>)
          : null,
      toc: json['toc'] != null
          ? TocRule.fromJson(json['toc'] as Map<String, dynamic>)
          : null,
      content: json['content'] != null
          ? ContentRule.fromJson(json['content'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'host': host,
      'contentType': contentType,
      'enabled': enabled,
      'weight': weight,
      if (search != null) 'search': search!.toJson(),
      if (bookInfo != null) 'bookInfo': bookInfo!.toJson(),
      if (toc != null) 'toc': toc!.toJson(),
      if (content != null) 'content': content!.toJson(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

class SearchRule {
  final String url;
  final String list;
  final String? bookName;
  final String? author;
  final String? cover;
  final String? intro;
  final String? bookUrl;
  final String? nextPage;

  const SearchRule({
    required this.url,
    required this.list,
    this.bookName,
    this.author,
    this.cover,
    this.intro,
    this.bookUrl,
    this.nextPage,
  });

  factory SearchRule.fromJson(Map<String, dynamic> json) {
    return SearchRule(
      url: json['url'] as String? ?? '',
      list: json['list'] as String? ?? '',
      bookName: json['bookName'] as String?,
      author: json['author'] as String?,
      cover: json['cover'] as String?,
      intro: json['intro'] as String?,
      bookUrl: json['bookUrl'] as String?,
      nextPage: json['nextPage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'list': list,
      if (bookName != null) 'bookName': bookName,
      if (author != null) 'author': author,
      if (cover != null) 'cover': cover,
      if (intro != null) 'intro': intro,
      if (bookUrl != null) 'bookUrl': bookUrl,
      if (nextPage != null) 'nextPage': nextPage,
    };
  }
}

class BookInfoRule {
  final String? cover;
  final String? intro;
  final String? author;
  final String? tocUrl;

  const BookInfoRule({
    this.cover,
    this.intro,
    this.author,
    this.tocUrl,
  });

  factory BookInfoRule.fromJson(Map<String, dynamic> json) {
    return BookInfoRule(
      cover: json['cover'] as String?,
      intro: json['intro'] as String?,
      author: json['author'] as String?,
      tocUrl: json['tocUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (cover != null) 'cover': cover,
      if (intro != null) 'intro': intro,
      if (author != null) 'author': author,
      if (tocUrl != null) 'tocUrl': tocUrl,
    };
  }
}

class TocRule {
  final String list;
  final String name;
  final String url;

  const TocRule({
    required this.list,
    required this.name,
    required this.url,
  });

  factory TocRule.fromJson(Map<String, dynamic> json) {
    return TocRule(
      list: json['list'] as String? ?? '',
      name: json['name'] as String? ?? '@text',
      url: json['url'] as String? ?? '@href',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'list': list,
      'name': name,
      'url': url,
    };
  }
}

class ContentRule {
  final String content;
  final String? nextPage;
  final String encoding;

  const ContentRule({
    required this.content,
    this.nextPage,
    this.encoding = 'utf-8',
  });

  factory ContentRule.fromJson(Map<String, dynamic> json) {
    return ContentRule(
      content: json['content'] as String? ?? '',
      nextPage: json['nextPage'] as String?,
      encoding: json['encoding'] as String? ?? 'utf-8',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (nextPage != null) 'nextPage': nextPage,
      'encoding': encoding,
    };
  }
}
