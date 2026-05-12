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
    // Auto-detect and convert Legado format
    if (_isLegadoFormat(json)) {
      json = _convertLegado(json);
    }
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

  static bool _isLegadoFormat(Map<String, dynamic> json) {
    return json.containsKey('bookSourceName') || json.containsKey('bookSourceUrl');
  }

  static Map<String, dynamic> _convertLegado(Map<String, dynamic> legado) {
    // Map bookSourceType to contentType string
    String contentType = 'novel';
    final type = legado['bookSourceType'] as int? ?? 0;
    if (type == 1) contentType = 'manga';

    // Convert search rule
    Map<String, dynamic>? search;
    final ruleSearch = legado['ruleSearch'] as Map<String, dynamic>?;
    final searchUrl = legado['searchUrl'] as String?;
    if (ruleSearch != null || searchUrl != null) {
      search = {
        if (searchUrl != null) 'url': searchUrl,
        if (ruleSearch?['bookList'] != null) 'list': ruleSearch!['bookList'],
        if (ruleSearch?['name'] != null) 'bookName': ruleSearch!['name'],
        if (ruleSearch?['author'] != null) 'author': ruleSearch!['author'],
        if (ruleSearch?['coverUrl'] != null) 'cover': ruleSearch!['coverUrl'],
        if (ruleSearch?['intro'] != null) 'intro': ruleSearch!['intro'],
        if (ruleSearch?['bookUrl'] != null) 'bookUrl': ruleSearch!['bookUrl'],
        if (ruleSearch?['nextPageUrl'] != null) 'nextPage': ruleSearch!['nextPageUrl'],
        if (ruleSearch?['header'] != null) 'headers': ruleSearch!['header'],
      };
    }

    // Convert bookInfo rule
    Map<String, dynamic>? bookInfo;
    final ruleBookInfo = legado['ruleBookInfo'] as Map<String, dynamic>?;
    if (ruleBookInfo != null) {
      bookInfo = {
        if (ruleBookInfo['coverUrl'] != null) 'cover': ruleBookInfo['coverUrl'],
        if (ruleBookInfo['intro'] != null) 'intro': ruleBookInfo['intro'],
        if (ruleBookInfo['author'] != null) 'author': ruleBookInfo['author'],
        if (ruleBookInfo['tocUrl'] != null) 'tocUrl': ruleBookInfo['tocUrl'],
      };
    }

    // Convert toc rule
    Map<String, dynamic>? toc;
    final ruleToc = legado['ruleToc'] as Map<String, dynamic>?;
    if (ruleToc != null) {
      toc = {
        if (ruleToc['chapterList'] != null) 'list': ruleToc['chapterList'],
        if (ruleToc['chapterName'] != null) 'name': ruleToc['chapterName'],
        if (ruleToc['chapterUrl'] != null) 'url': ruleToc['chapterUrl'],
      };
    }

    // Convert content rule
    Map<String, dynamic>? content;
    final ruleContent = legado['ruleContent'] as Map<String, dynamic>?;
    if (ruleContent != null) {
      content = {
        if (ruleContent['content'] != null) 'content': ruleContent['content'],
        if (ruleContent['nextContentUrl'] != null) 'nextPage': ruleContent['nextContentUrl'],
      };
    }

    return {
      'name': legado['bookSourceName'] as String? ?? '',
      'host': legado['bookSourceUrl'] as String? ?? '',
      'contentType': contentType,
      'enabled': legado['enabled'] as bool? ?? true,
      'weight': legado['weight'] as int? ?? 100,
      if (search != null) 'search': search,
      if (bookInfo != null) 'bookInfo': bookInfo,
      if (toc != null) 'toc': toc,
      if (content != null) 'content': content,
    };
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
  final String? headers;

  const SearchRule({
    required this.url,
    required this.list,
    this.bookName,
    this.author,
    this.cover,
    this.intro,
    this.bookUrl,
    this.nextPage,
    this.headers,
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
      headers: json['headers'] as String?,
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
      if (headers != null) 'headers': headers,
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
  final String? images;

  const ContentRule({
    required this.content,
    this.nextPage,
    this.encoding = 'utf-8',
    this.images,
  });

  factory ContentRule.fromJson(Map<String, dynamic> json) {
    return ContentRule(
      content: json['content'] as String? ?? '',
      nextPage: json['nextPage'] as String?,
      encoding: json['encoding'] as String? ?? 'utf-8',
      images: json['images'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (nextPage != null) 'nextPage': nextPage,
      'encoding': encoding,
      if (images != null) 'images': images,
    };
  }
}
