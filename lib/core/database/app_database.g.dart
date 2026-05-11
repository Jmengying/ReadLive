// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BookGroupsTableTable extends BookGroupsTable
    with TableInfo<$BookGroupsTableTable, BookGroupsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookGroupsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_groups_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<BookGroupsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookGroupsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookGroupsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookGroupsTableTable createAlias(String alias) {
    return $BookGroupsTableTable(attachedDatabase, alias);
  }
}

class BookGroupsTableData extends DataClass
    implements Insertable<BookGroupsTableData> {
  final String id;
  final String name;
  final int sortOrder;
  final int createdAt;
  const BookGroupsTableData(
      {required this.id,
      required this.name,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  BookGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return BookGroupsTableCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory BookGroupsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookGroupsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  BookGroupsTableData copyWith(
          {String? id, String? name, int? sortOrder, int? createdAt}) =>
      BookGroupsTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  BookGroupsTableData copyWithCompanion(BookGroupsTableCompanion data) {
    return BookGroupsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookGroupsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookGroupsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class BookGroupsTableCompanion extends UpdateCompanion<BookGroupsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> rowid;
  const BookGroupsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookGroupsTableCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<BookGroupsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookGroupsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? sortOrder,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return BookGroupsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BooksTableTable extends BooksTable
    with TableInfo<$BooksTableTable, BooksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 500),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverPathMeta =
      const VerificationMeta('coverPath');
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
      'cover_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bookUrlMeta =
      const VerificationMeta('bookUrl');
  @override
  late final GeneratedColumn<String> bookUrl = GeneratedColumn<String>(
      'book_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
      'content_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('novel'));
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES book_groups_table (id)'));
  static const VerificationMeta _lastReadAtMeta =
      const VerificationMeta('lastReadAt');
  @override
  late final GeneratedColumn<int> lastReadAt = GeneratedColumn<int>(
      'last_read_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
      'progress', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _lastChapterIndexMeta =
      const VerificationMeta('lastChapterIndex');
  @override
  late final GeneratedColumn<int> lastChapterIndex = GeneratedColumn<int>(
      'last_chapter_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastScrollOffsetMeta =
      const VerificationMeta('lastScrollOffset');
  @override
  late final GeneratedColumn<double> lastScrollOffset = GeneratedColumn<double>(
      'last_scroll_offset', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _lastPageIndexMeta =
      const VerificationMeta('lastPageIndex');
  @override
  late final GeneratedColumn<int> lastPageIndex = GeneratedColumn<int>(
      'last_page_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        author,
        coverPath,
        filePath,
        sourceId,
        bookUrl,
        contentType,
        groupId,
        lastReadAt,
        progress,
        lastChapterIndex,
        lastScrollOffset,
        lastPageIndex,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books_table';
  @override
  VerificationContext validateIntegrity(Insertable<BooksTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('cover_path')) {
      context.handle(_coverPathMeta,
          coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    }
    if (data.containsKey('book_url')) {
      context.handle(_bookUrlMeta,
          bookUrl.isAcceptableOrUnknown(data['book_url']!, _bookUrlMeta));
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
          _lastReadAtMeta,
          lastReadAt.isAcceptableOrUnknown(
              data['last_read_at']!, _lastReadAtMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('last_chapter_index')) {
      context.handle(
          _lastChapterIndexMeta,
          lastChapterIndex.isAcceptableOrUnknown(
              data['last_chapter_index']!, _lastChapterIndexMeta));
    }
    if (data.containsKey('last_scroll_offset')) {
      context.handle(
          _lastScrollOffsetMeta,
          lastScrollOffset.isAcceptableOrUnknown(
              data['last_scroll_offset']!, _lastScrollOffsetMeta));
    }
    if (data.containsKey('last_page_index')) {
      context.handle(
          _lastPageIndexMeta,
          lastPageIndex.isAcceptableOrUnknown(
              data['last_page_index']!, _lastPageIndexMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BooksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BooksTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      coverPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_path']),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id']),
      bookUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_url']),
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id']),
      lastReadAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_read_at']),
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}progress'])!,
      lastChapterIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_chapter_index'])!,
      lastScrollOffset: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}last_scroll_offset'])!,
      lastPageIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_page_index'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BooksTableTable createAlias(String alias) {
    return $BooksTableTable(attachedDatabase, alias);
  }
}

class BooksTableData extends DataClass implements Insertable<BooksTableData> {
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
  final double progress;
  final int lastChapterIndex;
  final double lastScrollOffset;
  final int lastPageIndex;
  final int createdAt;
  final int updatedAt;
  const BooksTableData(
      {required this.id,
      required this.title,
      this.author,
      this.coverPath,
      this.filePath,
      this.sourceId,
      this.bookUrl,
      required this.contentType,
      this.groupId,
      this.lastReadAt,
      required this.progress,
      required this.lastChapterIndex,
      required this.lastScrollOffset,
      required this.lastPageIndex,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || bookUrl != null) {
      map['book_url'] = Variable<String>(bookUrl);
    }
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<int>(lastReadAt);
    }
    map['progress'] = Variable<double>(progress);
    map['last_chapter_index'] = Variable<int>(lastChapterIndex);
    map['last_scroll_offset'] = Variable<double>(lastScrollOffset);
    map['last_page_index'] = Variable<int>(lastPageIndex);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BooksTableCompanion toCompanion(bool nullToAbsent) {
    return BooksTableCompanion(
      id: Value(id),
      title: Value(title),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      bookUrl: bookUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(bookUrl),
      contentType: Value(contentType),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
      progress: Value(progress),
      lastChapterIndex: Value(lastChapterIndex),
      lastScrollOffset: Value(lastScrollOffset),
      lastPageIndex: Value(lastPageIndex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BooksTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BooksTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      bookUrl: serializer.fromJson<String?>(json['bookUrl']),
      contentType: serializer.fromJson<String>(json['contentType']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      lastReadAt: serializer.fromJson<int?>(json['lastReadAt']),
      progress: serializer.fromJson<double>(json['progress']),
      lastChapterIndex: serializer.fromJson<int>(json['lastChapterIndex']),
      lastScrollOffset: serializer.fromJson<double>(json['lastScrollOffset']),
      lastPageIndex: serializer.fromJson<int>(json['lastPageIndex']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'coverPath': serializer.toJson<String?>(coverPath),
      'filePath': serializer.toJson<String?>(filePath),
      'sourceId': serializer.toJson<String?>(sourceId),
      'bookUrl': serializer.toJson<String?>(bookUrl),
      'contentType': serializer.toJson<String>(contentType),
      'groupId': serializer.toJson<String?>(groupId),
      'lastReadAt': serializer.toJson<int?>(lastReadAt),
      'progress': serializer.toJson<double>(progress),
      'lastChapterIndex': serializer.toJson<int>(lastChapterIndex),
      'lastScrollOffset': serializer.toJson<double>(lastScrollOffset),
      'lastPageIndex': serializer.toJson<int>(lastPageIndex),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  BooksTableData copyWith(
          {String? id,
          String? title,
          Value<String?> author = const Value.absent(),
          Value<String?> coverPath = const Value.absent(),
          Value<String?> filePath = const Value.absent(),
          Value<String?> sourceId = const Value.absent(),
          Value<String?> bookUrl = const Value.absent(),
          String? contentType,
          Value<String?> groupId = const Value.absent(),
          Value<int?> lastReadAt = const Value.absent(),
          double? progress,
          int? lastChapterIndex,
          double? lastScrollOffset,
          int? lastPageIndex,
          int? createdAt,
          int? updatedAt}) =>
      BooksTableData(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author.present ? author.value : this.author,
        coverPath: coverPath.present ? coverPath.value : this.coverPath,
        filePath: filePath.present ? filePath.value : this.filePath,
        sourceId: sourceId.present ? sourceId.value : this.sourceId,
        bookUrl: bookUrl.present ? bookUrl.value : this.bookUrl,
        contentType: contentType ?? this.contentType,
        groupId: groupId.present ? groupId.value : this.groupId,
        lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
        progress: progress ?? this.progress,
        lastChapterIndex: lastChapterIndex ?? this.lastChapterIndex,
        lastScrollOffset: lastScrollOffset ?? this.lastScrollOffset,
        lastPageIndex: lastPageIndex ?? this.lastPageIndex,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BooksTableData copyWithCompanion(BooksTableCompanion data) {
    return BooksTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      bookUrl: data.bookUrl.present ? data.bookUrl.value : this.bookUrl,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      lastReadAt:
          data.lastReadAt.present ? data.lastReadAt.value : this.lastReadAt,
      progress: data.progress.present ? data.progress.value : this.progress,
      lastChapterIndex: data.lastChapterIndex.present
          ? data.lastChapterIndex.value
          : this.lastChapterIndex,
      lastScrollOffset: data.lastScrollOffset.present
          ? data.lastScrollOffset.value
          : this.lastScrollOffset,
      lastPageIndex: data.lastPageIndex.present
          ? data.lastPageIndex.value
          : this.lastPageIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BooksTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverPath: $coverPath, ')
          ..write('filePath: $filePath, ')
          ..write('sourceId: $sourceId, ')
          ..write('bookUrl: $bookUrl, ')
          ..write('contentType: $contentType, ')
          ..write('groupId: $groupId, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('progress: $progress, ')
          ..write('lastChapterIndex: $lastChapterIndex, ')
          ..write('lastScrollOffset: $lastScrollOffset, ')
          ..write('lastPageIndex: $lastPageIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      author,
      coverPath,
      filePath,
      sourceId,
      bookUrl,
      contentType,
      groupId,
      lastReadAt,
      progress,
      lastChapterIndex,
      lastScrollOffset,
      lastPageIndex,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BooksTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.coverPath == this.coverPath &&
          other.filePath == this.filePath &&
          other.sourceId == this.sourceId &&
          other.bookUrl == this.bookUrl &&
          other.contentType == this.contentType &&
          other.groupId == this.groupId &&
          other.lastReadAt == this.lastReadAt &&
          other.progress == this.progress &&
          other.lastChapterIndex == this.lastChapterIndex &&
          other.lastScrollOffset == this.lastScrollOffset &&
          other.lastPageIndex == this.lastPageIndex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BooksTableCompanion extends UpdateCompanion<BooksTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> coverPath;
  final Value<String?> filePath;
  final Value<String?> sourceId;
  final Value<String?> bookUrl;
  final Value<String> contentType;
  final Value<String?> groupId;
  final Value<int?> lastReadAt;
  final Value<double> progress;
  final Value<int> lastChapterIndex;
  final Value<double> lastScrollOffset;
  final Value<int> lastPageIndex;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const BooksTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.bookUrl = const Value.absent(),
    this.contentType = const Value.absent(),
    this.groupId = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.progress = const Value.absent(),
    this.lastChapterIndex = const Value.absent(),
    this.lastScrollOffset = const Value.absent(),
    this.lastPageIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksTableCompanion.insert({
    required String id,
    required String title,
    this.author = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.bookUrl = const Value.absent(),
    this.contentType = const Value.absent(),
    this.groupId = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.progress = const Value.absent(),
    this.lastChapterIndex = const Value.absent(),
    this.lastScrollOffset = const Value.absent(),
    this.lastPageIndex = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<BooksTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? coverPath,
    Expression<String>? filePath,
    Expression<String>? sourceId,
    Expression<String>? bookUrl,
    Expression<String>? contentType,
    Expression<String>? groupId,
    Expression<int>? lastReadAt,
    Expression<double>? progress,
    Expression<int>? lastChapterIndex,
    Expression<double>? lastScrollOffset,
    Expression<int>? lastPageIndex,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (coverPath != null) 'cover_path': coverPath,
      if (filePath != null) 'file_path': filePath,
      if (sourceId != null) 'source_id': sourceId,
      if (bookUrl != null) 'book_url': bookUrl,
      if (contentType != null) 'content_type': contentType,
      if (groupId != null) 'group_id': groupId,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (progress != null) 'progress': progress,
      if (lastChapterIndex != null) 'last_chapter_index': lastChapterIndex,
      if (lastScrollOffset != null) 'last_scroll_offset': lastScrollOffset,
      if (lastPageIndex != null) 'last_page_index': lastPageIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? author,
      Value<String?>? coverPath,
      Value<String?>? filePath,
      Value<String?>? sourceId,
      Value<String?>? bookUrl,
      Value<String>? contentType,
      Value<String?>? groupId,
      Value<int?>? lastReadAt,
      Value<double>? progress,
      Value<int>? lastChapterIndex,
      Value<double>? lastScrollOffset,
      Value<int>? lastPageIndex,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return BooksTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      filePath: filePath ?? this.filePath,
      sourceId: sourceId ?? this.sourceId,
      bookUrl: bookUrl ?? this.bookUrl,
      contentType: contentType ?? this.contentType,
      groupId: groupId ?? this.groupId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      progress: progress ?? this.progress,
      lastChapterIndex: lastChapterIndex ?? this.lastChapterIndex,
      lastScrollOffset: lastScrollOffset ?? this.lastScrollOffset,
      lastPageIndex: lastPageIndex ?? this.lastPageIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (bookUrl.present) {
      map['book_url'] = Variable<String>(bookUrl.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<int>(lastReadAt.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (lastChapterIndex.present) {
      map['last_chapter_index'] = Variable<int>(lastChapterIndex.value);
    }
    if (lastScrollOffset.present) {
      map['last_scroll_offset'] = Variable<double>(lastScrollOffset.value);
    }
    if (lastPageIndex.present) {
      map['last_page_index'] = Variable<int>(lastPageIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverPath: $coverPath, ')
          ..write('filePath: $filePath, ')
          ..write('sourceId: $sourceId, ')
          ..write('bookUrl: $bookUrl, ')
          ..write('contentType: $contentType, ')
          ..write('groupId: $groupId, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('progress: $progress, ')
          ..write('lastChapterIndex: $lastChapterIndex, ')
          ..write('lastScrollOffset: $lastScrollOffset, ')
          ..write('lastPageIndex: $lastPageIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTableTable extends ChaptersTable
    with TableInfo<$ChaptersTableTable, ChaptersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES books_table (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chapterIndexMeta =
      const VerificationMeta('chapterIndex');
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
      'chapter_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isCachedMeta =
      const VerificationMeta('isCached');
  @override
  late final GeneratedColumn<bool> isCached = GeneratedColumn<bool>(
      'is_cached', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_cached" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, bookId, title, url, content, chapterIndex, isCached, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters_table';
  @override
  VerificationContext validateIntegrity(Insertable<ChaptersTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
          _chapterIndexMeta,
          chapterIndex.isAcceptableOrUnknown(
              data['chapter_index']!, _chapterIndexMeta));
    } else if (isInserting) {
      context.missing(_chapterIndexMeta);
    }
    if (data.containsKey('is_cached')) {
      context.handle(_isCachedMeta,
          isCached.isAcceptableOrUnknown(data['is_cached']!, _isCachedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChaptersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChaptersTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      chapterIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_index'])!,
      isCached: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_cached'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ChaptersTableTable createAlias(String alias) {
    return $ChaptersTableTable(attachedDatabase, alias);
  }
}

class ChaptersTableData extends DataClass
    implements Insertable<ChaptersTableData> {
  final String id;
  final String bookId;
  final String title;
  final String? url;
  final String? content;
  final int chapterIndex;
  final bool isCached;
  final int createdAt;
  const ChaptersTableData(
      {required this.id,
      required this.bookId,
      required this.title,
      this.url,
      this.content,
      required this.chapterIndex,
      required this.isCached,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['chapter_index'] = Variable<int>(chapterIndex);
    map['is_cached'] = Variable<bool>(isCached);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ChaptersTableCompanion toCompanion(bool nullToAbsent) {
    return ChaptersTableCompanion(
      id: Value(id),
      bookId: Value(bookId),
      title: Value(title),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      chapterIndex: Value(chapterIndex),
      isCached: Value(isCached),
      createdAt: Value(createdAt),
    );
  }

  factory ChaptersTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChaptersTableData(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String?>(json['url']),
      content: serializer.fromJson<String?>(json['content']),
      chapterIndex: serializer.fromJson<int>(json['chapterIndex']),
      isCached: serializer.fromJson<bool>(json['isCached']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String?>(url),
      'content': serializer.toJson<String?>(content),
      'chapterIndex': serializer.toJson<int>(chapterIndex),
      'isCached': serializer.toJson<bool>(isCached),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ChaptersTableData copyWith(
          {String? id,
          String? bookId,
          String? title,
          Value<String?> url = const Value.absent(),
          Value<String?> content = const Value.absent(),
          int? chapterIndex,
          bool? isCached,
          int? createdAt}) =>
      ChaptersTableData(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        title: title ?? this.title,
        url: url.present ? url.value : this.url,
        content: content.present ? content.value : this.content,
        chapterIndex: chapterIndex ?? this.chapterIndex,
        isCached: isCached ?? this.isCached,
        createdAt: createdAt ?? this.createdAt,
      );
  ChaptersTableData copyWithCompanion(ChaptersTableCompanion data) {
    return ChaptersTableData(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      content: data.content.present ? data.content.value : this.content,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      isCached: data.isCached.present ? data.isCached.value : this.isCached,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersTableData(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('content: $content, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('isCached: $isCached, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, bookId, title, url, content, chapterIndex, isCached, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChaptersTableData &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.title == this.title &&
          other.url == this.url &&
          other.content == this.content &&
          other.chapterIndex == this.chapterIndex &&
          other.isCached == this.isCached &&
          other.createdAt == this.createdAt);
}

class ChaptersTableCompanion extends UpdateCompanion<ChaptersTableData> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> title;
  final Value<String?> url;
  final Value<String?> content;
  final Value<int> chapterIndex;
  final Value<bool> isCached;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ChaptersTableCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.content = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.isCached = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersTableCompanion.insert({
    required String id,
    required String bookId,
    required String title,
    this.url = const Value.absent(),
    this.content = const Value.absent(),
    required int chapterIndex,
    this.isCached = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bookId = Value(bookId),
        title = Value(title),
        chapterIndex = Value(chapterIndex),
        createdAt = Value(createdAt);
  static Insertable<ChaptersTableData> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? title,
    Expression<String>? url,
    Expression<String>? content,
    Expression<int>? chapterIndex,
    Expression<bool>? isCached,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (content != null) 'content': content,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (isCached != null) 'is_cached': isCached,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? bookId,
      Value<String>? title,
      Value<String?>? url,
      Value<String?>? content,
      Value<int>? chapterIndex,
      Value<bool>? isCached,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return ChaptersTableCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      url: url ?? this.url,
      content: content ?? this.content,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      isCached: isCached ?? this.isCached,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (isCached.present) {
      map['is_cached'] = Variable<bool>(isCached.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersTableCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('content: $content, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('isCached: $isCached, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTableTable extends BookmarksTable
    with TableInfo<$BookmarksTableTable, BookmarksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES books_table (id)'));
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES chapters_table (id)'));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startOffsetMeta =
      const VerificationMeta('startOffset');
  @override
  late final GeneratedColumn<int> startOffset = GeneratedColumn<int>(
      'start_offset', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endOffsetMeta =
      const VerificationMeta('endOffset');
  @override
  late final GeneratedColumn<int> endOffset = GeneratedColumn<int>(
      'end_offset', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _contentPreviewMeta =
      const VerificationMeta('contentPreview');
  @override
  late final GeneratedColumn<String> contentPreview = GeneratedColumn<String>(
      'content_preview', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _highlightColorMeta =
      const VerificationMeta('highlightColor');
  @override
  late final GeneratedColumn<String> highlightColor = GeneratedColumn<String>(
      'highlight_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('bookmark'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        bookId,
        chapterId,
        position,
        startOffset,
        endOffset,
        contentPreview,
        note,
        highlightColor,
        type,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks_table';
  @override
  VerificationContext validateIntegrity(Insertable<BookmarksTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('start_offset')) {
      context.handle(
          _startOffsetMeta,
          startOffset.isAcceptableOrUnknown(
              data['start_offset']!, _startOffsetMeta));
    }
    if (data.containsKey('end_offset')) {
      context.handle(_endOffsetMeta,
          endOffset.isAcceptableOrUnknown(data['end_offset']!, _endOffsetMeta));
    }
    if (data.containsKey('content_preview')) {
      context.handle(
          _contentPreviewMeta,
          contentPreview.isAcceptableOrUnknown(
              data['content_preview']!, _contentPreviewMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('highlight_color')) {
      context.handle(
          _highlightColorMeta,
          highlightColor.isAcceptableOrUnknown(
              data['highlight_color']!, _highlightColorMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookmarksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarksTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      startOffset: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_offset']),
      endOffset: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_offset']),
      contentPreview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_preview']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      highlightColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}highlight_color']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookmarksTableTable createAlias(String alias) {
    return $BookmarksTableTable(attachedDatabase, alias);
  }
}

class BookmarksTableData extends DataClass
    implements Insertable<BookmarksTableData> {
  final String id;
  final String bookId;
  final String chapterId;
  final int position;
  final int? startOffset;
  final int? endOffset;
  final String? contentPreview;
  final String? note;
  final String? highlightColor;
  final String type;
  final int createdAt;
  const BookmarksTableData(
      {required this.id,
      required this.bookId,
      required this.chapterId,
      required this.position,
      this.startOffset,
      this.endOffset,
      this.contentPreview,
      this.note,
      this.highlightColor,
      required this.type,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['chapter_id'] = Variable<String>(chapterId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || startOffset != null) {
      map['start_offset'] = Variable<int>(startOffset);
    }
    if (!nullToAbsent || endOffset != null) {
      map['end_offset'] = Variable<int>(endOffset);
    }
    if (!nullToAbsent || contentPreview != null) {
      map['content_preview'] = Variable<String>(contentPreview);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || highlightColor != null) {
      map['highlight_color'] = Variable<String>(highlightColor);
    }
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  BookmarksTableCompanion toCompanion(bool nullToAbsent) {
    return BookmarksTableCompanion(
      id: Value(id),
      bookId: Value(bookId),
      chapterId: Value(chapterId),
      position: Value(position),
      startOffset: startOffset == null && nullToAbsent
          ? const Value.absent()
          : Value(startOffset),
      endOffset: endOffset == null && nullToAbsent
          ? const Value.absent()
          : Value(endOffset),
      contentPreview: contentPreview == null && nullToAbsent
          ? const Value.absent()
          : Value(contentPreview),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      highlightColor: highlightColor == null && nullToAbsent
          ? const Value.absent()
          : Value(highlightColor),
      type: Value(type),
      createdAt: Value(createdAt),
    );
  }

  factory BookmarksTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarksTableData(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      position: serializer.fromJson<int>(json['position']),
      startOffset: serializer.fromJson<int?>(json['startOffset']),
      endOffset: serializer.fromJson<int?>(json['endOffset']),
      contentPreview: serializer.fromJson<String?>(json['contentPreview']),
      note: serializer.fromJson<String?>(json['note']),
      highlightColor: serializer.fromJson<String?>(json['highlightColor']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'chapterId': serializer.toJson<String>(chapterId),
      'position': serializer.toJson<int>(position),
      'startOffset': serializer.toJson<int?>(startOffset),
      'endOffset': serializer.toJson<int?>(endOffset),
      'contentPreview': serializer.toJson<String?>(contentPreview),
      'note': serializer.toJson<String?>(note),
      'highlightColor': serializer.toJson<String?>(highlightColor),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  BookmarksTableData copyWith(
          {String? id,
          String? bookId,
          String? chapterId,
          int? position,
          Value<int?> startOffset = const Value.absent(),
          Value<int?> endOffset = const Value.absent(),
          Value<String?> contentPreview = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<String?> highlightColor = const Value.absent(),
          String? type,
          int? createdAt}) =>
      BookmarksTableData(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        chapterId: chapterId ?? this.chapterId,
        position: position ?? this.position,
        startOffset: startOffset.present ? startOffset.value : this.startOffset,
        endOffset: endOffset.present ? endOffset.value : this.endOffset,
        contentPreview:
            contentPreview.present ? contentPreview.value : this.contentPreview,
        note: note.present ? note.value : this.note,
        highlightColor:
            highlightColor.present ? highlightColor.value : this.highlightColor,
        type: type ?? this.type,
        createdAt: createdAt ?? this.createdAt,
      );
  BookmarksTableData copyWithCompanion(BookmarksTableCompanion data) {
    return BookmarksTableData(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      position: data.position.present ? data.position.value : this.position,
      startOffset:
          data.startOffset.present ? data.startOffset.value : this.startOffset,
      endOffset: data.endOffset.present ? data.endOffset.value : this.endOffset,
      contentPreview: data.contentPreview.present
          ? data.contentPreview.value
          : this.contentPreview,
      note: data.note.present ? data.note.value : this.note,
      highlightColor: data.highlightColor.present
          ? data.highlightColor.value
          : this.highlightColor,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksTableData(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('position: $position, ')
          ..write('startOffset: $startOffset, ')
          ..write('endOffset: $endOffset, ')
          ..write('contentPreview: $contentPreview, ')
          ..write('note: $note, ')
          ..write('highlightColor: $highlightColor, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bookId, chapterId, position, startOffset,
      endOffset, contentPreview, note, highlightColor, type, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarksTableData &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.position == this.position &&
          other.startOffset == this.startOffset &&
          other.endOffset == this.endOffset &&
          other.contentPreview == this.contentPreview &&
          other.note == this.note &&
          other.highlightColor == this.highlightColor &&
          other.type == this.type &&
          other.createdAt == this.createdAt);
}

class BookmarksTableCompanion extends UpdateCompanion<BookmarksTableData> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> chapterId;
  final Value<int> position;
  final Value<int?> startOffset;
  final Value<int?> endOffset;
  final Value<String?> contentPreview;
  final Value<String?> note;
  final Value<String?> highlightColor;
  final Value<String> type;
  final Value<int> createdAt;
  final Value<int> rowid;
  const BookmarksTableCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.position = const Value.absent(),
    this.startOffset = const Value.absent(),
    this.endOffset = const Value.absent(),
    this.contentPreview = const Value.absent(),
    this.note = const Value.absent(),
    this.highlightColor = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksTableCompanion.insert({
    required String id,
    required String bookId,
    required String chapterId,
    required int position,
    this.startOffset = const Value.absent(),
    this.endOffset = const Value.absent(),
    this.contentPreview = const Value.absent(),
    this.note = const Value.absent(),
    this.highlightColor = const Value.absent(),
    this.type = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bookId = Value(bookId),
        chapterId = Value(chapterId),
        position = Value(position),
        createdAt = Value(createdAt);
  static Insertable<BookmarksTableData> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? chapterId,
    Expression<int>? position,
    Expression<int>? startOffset,
    Expression<int>? endOffset,
    Expression<String>? contentPreview,
    Expression<String>? note,
    Expression<String>? highlightColor,
    Expression<String>? type,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (position != null) 'position': position,
      if (startOffset != null) 'start_offset': startOffset,
      if (endOffset != null) 'end_offset': endOffset,
      if (contentPreview != null) 'content_preview': contentPreview,
      if (note != null) 'note': note,
      if (highlightColor != null) 'highlight_color': highlightColor,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? bookId,
      Value<String>? chapterId,
      Value<int>? position,
      Value<int?>? startOffset,
      Value<int?>? endOffset,
      Value<String?>? contentPreview,
      Value<String?>? note,
      Value<String?>? highlightColor,
      Value<String>? type,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return BookmarksTableCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      position: position ?? this.position,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      contentPreview: contentPreview ?? this.contentPreview,
      note: note ?? this.note,
      highlightColor: highlightColor ?? this.highlightColor,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (startOffset.present) {
      map['start_offset'] = Variable<int>(startOffset.value);
    }
    if (endOffset.present) {
      map['end_offset'] = Variable<int>(endOffset.value);
    }
    if (contentPreview.present) {
      map['content_preview'] = Variable<String>(contentPreview.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (highlightColor.present) {
      map['highlight_color'] = Variable<String>(highlightColor.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksTableCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('position: $position, ')
          ..write('startOffset: $startOffset, ')
          ..write('endOffset: $endOffset, ')
          ..write('contentPreview: $contentPreview, ')
          ..write('note: $note, ')
          ..write('highlightColor: $highlightColor, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookSourcesTableTable extends BookSourcesTable
    with TableInfo<$BookSourcesTableTable, BookSourcesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookSourcesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
      'host', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
      'content_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('novel'));
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<int> weight = GeneratedColumn<int>(
      'weight', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _ruleJsonMeta =
      const VerificationMeta('ruleJson');
  @override
  late final GeneratedColumn<String> ruleJson = GeneratedColumn<String>(
      'rule_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _lastTestedAtMeta =
      const VerificationMeta('lastTestedAt');
  @override
  late final GeneratedColumn<int> lastTestedAt = GeneratedColumn<int>(
      'last_tested_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _groupNameMeta =
      const VerificationMeta('groupName');
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
      'group_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _builtInMeta =
      const VerificationMeta('builtIn');
  @override
  late final GeneratedColumn<bool> builtIn = GeneratedColumn<bool>(
      'built_in', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("built_in" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        host,
        contentType,
        enabled,
        weight,
        ruleJson,
        status,
        lastTestedAt,
        groupName,
        builtIn,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_sources_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<BookSourcesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
          _hostMeta, host.isAcceptableOrUnknown(data['host']!, _hostMeta));
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('rule_json')) {
      context.handle(_ruleJsonMeta,
          ruleJson.isAcceptableOrUnknown(data['rule_json']!, _ruleJsonMeta));
    } else if (isInserting) {
      context.missing(_ruleJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('last_tested_at')) {
      context.handle(
          _lastTestedAtMeta,
          lastTestedAt.isAcceptableOrUnknown(
              data['last_tested_at']!, _lastTestedAtMeta));
    }
    if (data.containsKey('group_name')) {
      context.handle(_groupNameMeta,
          groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta));
    }
    if (data.containsKey('built_in')) {
      context.handle(_builtInMeta,
          builtIn.isAcceptableOrUnknown(data['built_in']!, _builtInMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookSourcesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookSourcesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      host: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}host'])!,
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weight'])!,
      ruleJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rule_json'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      lastTestedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_tested_at']),
      groupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_name']),
      builtIn: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}built_in'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookSourcesTableTable createAlias(String alias) {
    return $BookSourcesTableTable(attachedDatabase, alias);
  }
}

class BookSourcesTableData extends DataClass
    implements Insertable<BookSourcesTableData> {
  final String id;
  final String name;
  final String host;
  final String contentType;
  final bool enabled;
  final int weight;
  final String ruleJson;
  final String status;
  final int? lastTestedAt;
  final String? groupName;
  final bool builtIn;
  final int createdAt;
  const BookSourcesTableData(
      {required this.id,
      required this.name,
      required this.host,
      required this.contentType,
      required this.enabled,
      required this.weight,
      required this.ruleJson,
      required this.status,
      this.lastTestedAt,
      this.groupName,
      required this.builtIn,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['host'] = Variable<String>(host);
    map['content_type'] = Variable<String>(contentType);
    map['enabled'] = Variable<bool>(enabled);
    map['weight'] = Variable<int>(weight);
    map['rule_json'] = Variable<String>(ruleJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastTestedAt != null) {
      map['last_tested_at'] = Variable<int>(lastTestedAt);
    }
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    map['built_in'] = Variable<bool>(builtIn);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  BookSourcesTableCompanion toCompanion(bool nullToAbsent) {
    return BookSourcesTableCompanion(
      id: Value(id),
      name: Value(name),
      host: Value(host),
      contentType: Value(contentType),
      enabled: Value(enabled),
      weight: Value(weight),
      ruleJson: Value(ruleJson),
      status: Value(status),
      lastTestedAt: lastTestedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTestedAt),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      builtIn: Value(builtIn),
      createdAt: Value(createdAt),
    );
  }

  factory BookSourcesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookSourcesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      host: serializer.fromJson<String>(json['host']),
      contentType: serializer.fromJson<String>(json['contentType']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      weight: serializer.fromJson<int>(json['weight']),
      ruleJson: serializer.fromJson<String>(json['ruleJson']),
      status: serializer.fromJson<String>(json['status']),
      lastTestedAt: serializer.fromJson<int?>(json['lastTestedAt']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      builtIn: serializer.fromJson<bool>(json['builtIn']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'host': serializer.toJson<String>(host),
      'contentType': serializer.toJson<String>(contentType),
      'enabled': serializer.toJson<bool>(enabled),
      'weight': serializer.toJson<int>(weight),
      'ruleJson': serializer.toJson<String>(ruleJson),
      'status': serializer.toJson<String>(status),
      'lastTestedAt': serializer.toJson<int?>(lastTestedAt),
      'groupName': serializer.toJson<String?>(groupName),
      'builtIn': serializer.toJson<bool>(builtIn),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  BookSourcesTableData copyWith(
          {String? id,
          String? name,
          String? host,
          String? contentType,
          bool? enabled,
          int? weight,
          String? ruleJson,
          String? status,
          Value<int?> lastTestedAt = const Value.absent(),
          Value<String?> groupName = const Value.absent(),
          bool? builtIn,
          int? createdAt}) =>
      BookSourcesTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        host: host ?? this.host,
        contentType: contentType ?? this.contentType,
        enabled: enabled ?? this.enabled,
        weight: weight ?? this.weight,
        ruleJson: ruleJson ?? this.ruleJson,
        status: status ?? this.status,
        lastTestedAt:
            lastTestedAt.present ? lastTestedAt.value : this.lastTestedAt,
        groupName: groupName.present ? groupName.value : this.groupName,
        builtIn: builtIn ?? this.builtIn,
        createdAt: createdAt ?? this.createdAt,
      );
  BookSourcesTableData copyWithCompanion(BookSourcesTableCompanion data) {
    return BookSourcesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      host: data.host.present ? data.host.value : this.host,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      weight: data.weight.present ? data.weight.value : this.weight,
      ruleJson: data.ruleJson.present ? data.ruleJson.value : this.ruleJson,
      status: data.status.present ? data.status.value : this.status,
      lastTestedAt: data.lastTestedAt.present
          ? data.lastTestedAt.value
          : this.lastTestedAt,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      builtIn: data.builtIn.present ? data.builtIn.value : this.builtIn,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookSourcesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('contentType: $contentType, ')
          ..write('enabled: $enabled, ')
          ..write('weight: $weight, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('status: $status, ')
          ..write('lastTestedAt: $lastTestedAt, ')
          ..write('groupName: $groupName, ')
          ..write('builtIn: $builtIn, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, host, contentType, enabled, weight,
      ruleJson, status, lastTestedAt, groupName, builtIn, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookSourcesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.host == this.host &&
          other.contentType == this.contentType &&
          other.enabled == this.enabled &&
          other.weight == this.weight &&
          other.ruleJson == this.ruleJson &&
          other.status == this.status &&
          other.lastTestedAt == this.lastTestedAt &&
          other.groupName == this.groupName &&
          other.builtIn == this.builtIn &&
          other.createdAt == this.createdAt);
}

class BookSourcesTableCompanion extends UpdateCompanion<BookSourcesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> host;
  final Value<String> contentType;
  final Value<bool> enabled;
  final Value<int> weight;
  final Value<String> ruleJson;
  final Value<String> status;
  final Value<int?> lastTestedAt;
  final Value<String?> groupName;
  final Value<bool> builtIn;
  final Value<int> createdAt;
  final Value<int> rowid;
  const BookSourcesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.host = const Value.absent(),
    this.contentType = const Value.absent(),
    this.enabled = const Value.absent(),
    this.weight = const Value.absent(),
    this.ruleJson = const Value.absent(),
    this.status = const Value.absent(),
    this.lastTestedAt = const Value.absent(),
    this.groupName = const Value.absent(),
    this.builtIn = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookSourcesTableCompanion.insert({
    required String id,
    required String name,
    required String host,
    this.contentType = const Value.absent(),
    this.enabled = const Value.absent(),
    this.weight = const Value.absent(),
    required String ruleJson,
    this.status = const Value.absent(),
    this.lastTestedAt = const Value.absent(),
    this.groupName = const Value.absent(),
    this.builtIn = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        host = Value(host),
        ruleJson = Value(ruleJson),
        createdAt = Value(createdAt);
  static Insertable<BookSourcesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? host,
    Expression<String>? contentType,
    Expression<bool>? enabled,
    Expression<int>? weight,
    Expression<String>? ruleJson,
    Expression<String>? status,
    Expression<int>? lastTestedAt,
    Expression<String>? groupName,
    Expression<bool>? builtIn,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (host != null) 'host': host,
      if (contentType != null) 'content_type': contentType,
      if (enabled != null) 'enabled': enabled,
      if (weight != null) 'weight': weight,
      if (ruleJson != null) 'rule_json': ruleJson,
      if (status != null) 'status': status,
      if (lastTestedAt != null) 'last_tested_at': lastTestedAt,
      if (groupName != null) 'group_name': groupName,
      if (builtIn != null) 'built_in': builtIn,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookSourcesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? host,
      Value<String>? contentType,
      Value<bool>? enabled,
      Value<int>? weight,
      Value<String>? ruleJson,
      Value<String>? status,
      Value<int?>? lastTestedAt,
      Value<String?>? groupName,
      Value<bool>? builtIn,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return BookSourcesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      contentType: contentType ?? this.contentType,
      enabled: enabled ?? this.enabled,
      weight: weight ?? this.weight,
      ruleJson: ruleJson ?? this.ruleJson,
      status: status ?? this.status,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      groupName: groupName ?? this.groupName,
      builtIn: builtIn ?? this.builtIn,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (weight.present) {
      map['weight'] = Variable<int>(weight.value);
    }
    if (ruleJson.present) {
      map['rule_json'] = Variable<String>(ruleJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastTestedAt.present) {
      map['last_tested_at'] = Variable<int>(lastTestedAt.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (builtIn.present) {
      map['built_in'] = Variable<bool>(builtIn.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookSourcesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('contentType: $contentType, ')
          ..write('enabled: $enabled, ')
          ..write('weight: $weight, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('status: $status, ')
          ..write('lastTestedAt: $lastTestedAt, ')
          ..write('groupName: $groupName, ')
          ..write('builtIn: $builtIn, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTableTable extends ReadingSessionsTable
    with TableInfo<$ReadingSessionsTableTable, ReadingSessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES books_table (id)'));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
      'end_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _wordsReadMeta =
      const VerificationMeta('wordsRead');
  @override
  late final GeneratedColumn<int> wordsRead = GeneratedColumn<int>(
      'words_read', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, bookId, startTime, endTime, durationSeconds, wordsRead];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<ReadingSessionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('words_read')) {
      context.handle(_wordsReadMeta,
          wordsRead.isAcceptableOrUnknown(data['words_read']!, _wordsReadMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSessionsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSessionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_time'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      wordsRead: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}words_read'])!,
    );
  }

  @override
  $ReadingSessionsTableTable createAlias(String alias) {
    return $ReadingSessionsTableTable(attachedDatabase, alias);
  }
}

class ReadingSessionsTableData extends DataClass
    implements Insertable<ReadingSessionsTableData> {
  final String id;
  final String bookId;
  final int startTime;
  final int endTime;
  final int durationSeconds;
  final int wordsRead;
  const ReadingSessionsTableData(
      {required this.id,
      required this.bookId,
      required this.startTime,
      required this.endTime,
      required this.durationSeconds,
      required this.wordsRead});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['start_time'] = Variable<int>(startTime);
    map['end_time'] = Variable<int>(endTime);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['words_read'] = Variable<int>(wordsRead);
    return map;
  }

  ReadingSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsTableCompanion(
      id: Value(id),
      bookId: Value(bookId),
      startTime: Value(startTime),
      endTime: Value(endTime),
      durationSeconds: Value(durationSeconds),
      wordsRead: Value(wordsRead),
    );
  }

  factory ReadingSessionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSessionsTableData(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      startTime: serializer.fromJson<int>(json['startTime']),
      endTime: serializer.fromJson<int>(json['endTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      wordsRead: serializer.fromJson<int>(json['wordsRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'startTime': serializer.toJson<int>(startTime),
      'endTime': serializer.toJson<int>(endTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'wordsRead': serializer.toJson<int>(wordsRead),
    };
  }

  ReadingSessionsTableData copyWith(
          {String? id,
          String? bookId,
          int? startTime,
          int? endTime,
          int? durationSeconds,
          int? wordsRead}) =>
      ReadingSessionsTableData(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        wordsRead: wordsRead ?? this.wordsRead,
      );
  ReadingSessionsTableData copyWithCompanion(
      ReadingSessionsTableCompanion data) {
    return ReadingSessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      wordsRead: data.wordsRead.present ? data.wordsRead.value : this.wordsRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsTableData(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('wordsRead: $wordsRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, startTime, endTime, durationSeconds, wordsRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSessionsTableData &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationSeconds == this.durationSeconds &&
          other.wordsRead == this.wordsRead);
}

class ReadingSessionsTableCompanion
    extends UpdateCompanion<ReadingSessionsTableData> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<int> startTime;
  final Value<int> endTime;
  final Value<int> durationSeconds;
  final Value<int> wordsRead;
  final Value<int> rowid;
  const ReadingSessionsTableCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.wordsRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingSessionsTableCompanion.insert({
    required String id,
    required String bookId,
    required int startTime,
    required int endTime,
    required int durationSeconds,
    this.wordsRead = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bookId = Value(bookId),
        startTime = Value(startTime),
        endTime = Value(endTime),
        durationSeconds = Value(durationSeconds);
  static Insertable<ReadingSessionsTableData> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<int>? durationSeconds,
    Expression<int>? wordsRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (wordsRead != null) 'words_read': wordsRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingSessionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? bookId,
      Value<int>? startTime,
      Value<int>? endTime,
      Value<int>? durationSeconds,
      Value<int>? wordsRead,
      Value<int>? rowid}) {
    return ReadingSessionsTableCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      wordsRead: wordsRead ?? this.wordsRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (wordsRead.present) {
      map['words_read'] = Variable<int>(wordsRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('wordsRead: $wordsRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BookGroupsTableTable bookGroupsTable =
      $BookGroupsTableTable(this);
  late final $BooksTableTable booksTable = $BooksTableTable(this);
  late final $ChaptersTableTable chaptersTable = $ChaptersTableTable(this);
  late final $BookmarksTableTable bookmarksTable = $BookmarksTableTable(this);
  late final $BookSourcesTableTable bookSourcesTable =
      $BookSourcesTableTable(this);
  late final $ReadingSessionsTableTable readingSessionsTable =
      $ReadingSessionsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        bookGroupsTable,
        booksTable,
        chaptersTable,
        bookmarksTable,
        bookSourcesTable,
        readingSessionsTable
      ];
}

typedef $$BookGroupsTableTableCreateCompanionBuilder = BookGroupsTableCompanion
    Function({
  required String id,
  required String name,
  Value<int> sortOrder,
  required int createdAt,
  Value<int> rowid,
});
typedef $$BookGroupsTableTableUpdateCompanionBuilder = BookGroupsTableCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$BookGroupsTableTableReferences extends BaseReferences<
    _$AppDatabase, $BookGroupsTableTable, BookGroupsTableData> {
  $$BookGroupsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BooksTableTable, List<BooksTableData>>
      _booksTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.booksTable,
              aliasName: $_aliasNameGenerator(
                  db.bookGroupsTable.id, db.booksTable.groupId));

  $$BooksTableTableProcessedTableManager get booksTableRefs {
    final manager = $$BooksTableTableTableManager($_db, $_db.booksTable)
        .filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_booksTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BookGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $BookGroupsTableTable> {
  $$BookGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> booksTableRefs(
      Expression<bool> Function($$BooksTableTableFilterComposer f) f) {
    final $$BooksTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableFilterComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BookGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BookGroupsTableTable> {
  $$BookGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BookGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookGroupsTableTable> {
  $$BookGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> booksTableRefs<T extends Object>(
      Expression<T> Function($$BooksTableTableAnnotationComposer a) f) {
    final $$BooksTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableAnnotationComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BookGroupsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookGroupsTableTable,
    BookGroupsTableData,
    $$BookGroupsTableTableFilterComposer,
    $$BookGroupsTableTableOrderingComposer,
    $$BookGroupsTableTableAnnotationComposer,
    $$BookGroupsTableTableCreateCompanionBuilder,
    $$BookGroupsTableTableUpdateCompanionBuilder,
    (BookGroupsTableData, $$BookGroupsTableTableReferences),
    BookGroupsTableData,
    PrefetchHooks Function({bool booksTableRefs})> {
  $$BookGroupsTableTableTableManager(
      _$AppDatabase db, $BookGroupsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookGroupsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookGroupsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookGroupsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookGroupsTableCompanion(
            id: id,
            name: name,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int> sortOrder = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BookGroupsTableCompanion.insert(
            id: id,
            name: name,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BookGroupsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({booksTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (booksTableRefs) db.booksTable],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (booksTableRefs)
                    await $_getPrefetchedData<BookGroupsTableData,
                            $BookGroupsTableTable, BooksTableData>(
                        currentTable: table,
                        referencedTable: $$BookGroupsTableTableReferences
                            ._booksTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BookGroupsTableTableReferences(db, table, p0)
                                .booksTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.groupId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BookGroupsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookGroupsTableTable,
    BookGroupsTableData,
    $$BookGroupsTableTableFilterComposer,
    $$BookGroupsTableTableOrderingComposer,
    $$BookGroupsTableTableAnnotationComposer,
    $$BookGroupsTableTableCreateCompanionBuilder,
    $$BookGroupsTableTableUpdateCompanionBuilder,
    (BookGroupsTableData, $$BookGroupsTableTableReferences),
    BookGroupsTableData,
    PrefetchHooks Function({bool booksTableRefs})>;
typedef $$BooksTableTableCreateCompanionBuilder = BooksTableCompanion Function({
  required String id,
  required String title,
  Value<String?> author,
  Value<String?> coverPath,
  Value<String?> filePath,
  Value<String?> sourceId,
  Value<String?> bookUrl,
  Value<String> contentType,
  Value<String?> groupId,
  Value<int?> lastReadAt,
  Value<double> progress,
  Value<int> lastChapterIndex,
  Value<double> lastScrollOffset,
  Value<int> lastPageIndex,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$BooksTableTableUpdateCompanionBuilder = BooksTableCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> author,
  Value<String?> coverPath,
  Value<String?> filePath,
  Value<String?> sourceId,
  Value<String?> bookUrl,
  Value<String> contentType,
  Value<String?> groupId,
  Value<int?> lastReadAt,
  Value<double> progress,
  Value<int> lastChapterIndex,
  Value<double> lastScrollOffset,
  Value<int> lastPageIndex,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$BooksTableTableReferences
    extends BaseReferences<_$AppDatabase, $BooksTableTable, BooksTableData> {
  $$BooksTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BookGroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.bookGroupsTable.createAlias(
          $_aliasNameGenerator(db.booksTable.groupId, db.bookGroupsTable.id));

  $$BookGroupsTableTableProcessedTableManager? get groupId {
    final $_column = $_itemColumn<String>('group_id');
    if ($_column == null) return null;
    final manager =
        $$BookGroupsTableTableTableManager($_db, $_db.bookGroupsTable)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ChaptersTableTable, List<ChaptersTableData>>
      _chaptersTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.chaptersTable,
              aliasName: $_aliasNameGenerator(
                  db.booksTable.id, db.chaptersTable.bookId));

  $$ChaptersTableTableProcessedTableManager get chaptersTableRefs {
    final manager = $$ChaptersTableTableTableManager($_db, $_db.chaptersTable)
        .filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BookmarksTableTable, List<BookmarksTableData>>
      _bookmarksTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.bookmarksTable,
              aliasName: $_aliasNameGenerator(
                  db.booksTable.id, db.bookmarksTable.bookId));

  $$BookmarksTableTableProcessedTableManager get bookmarksTableRefs {
    final manager = $$BookmarksTableTableTableManager($_db, $_db.bookmarksTable)
        .filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReadingSessionsTableTable,
      List<ReadingSessionsTableData>> _readingSessionsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.readingSessionsTable,
          aliasName: $_aliasNameGenerator(
              db.booksTable.id, db.readingSessionsTable.bookId));

  $$ReadingSessionsTableTableProcessedTableManager
      get readingSessionsTableRefs {
    final manager =
        $$ReadingSessionsTableTableTableManager($_db, $_db.readingSessionsTable)
            .filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_readingSessionsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BooksTableTableFilterComposer
    extends Composer<_$AppDatabase, $BooksTableTable> {
  $$BooksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookUrl => $composableBuilder(
      column: $table.bookUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastReadAt => $composableBuilder(
      column: $table.lastReadAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastChapterIndex => $composableBuilder(
      column: $table.lastChapterIndex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lastScrollOffset => $composableBuilder(
      column: $table.lastScrollOffset,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPageIndex => $composableBuilder(
      column: $table.lastPageIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$BookGroupsTableTableFilterComposer get groupId {
    final $$BookGroupsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.bookGroupsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookGroupsTableTableFilterComposer(
              $db: $db,
              $table: $db.bookGroupsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> chaptersTableRefs(
      Expression<bool> Function($$ChaptersTableTableFilterComposer f) f) {
    final $$ChaptersTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chaptersTable,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableTableFilterComposer(
              $db: $db,
              $table: $db.chaptersTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> bookmarksTableRefs(
      Expression<bool> Function($$BookmarksTableTableFilterComposer f) f) {
    final $$BookmarksTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarksTable,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableTableFilterComposer(
              $db: $db,
              $table: $db.bookmarksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> readingSessionsTableRefs(
      Expression<bool> Function($$ReadingSessionsTableTableFilterComposer f)
          f) {
    final $$ReadingSessionsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.readingSessionsTable,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingSessionsTableTableFilterComposer(
              $db: $db,
              $table: $db.readingSessionsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BooksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTableTable> {
  $$BooksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookUrl => $composableBuilder(
      column: $table.bookUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastReadAt => $composableBuilder(
      column: $table.lastReadAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastChapterIndex => $composableBuilder(
      column: $table.lastChapterIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lastScrollOffset => $composableBuilder(
      column: $table.lastScrollOffset,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPageIndex => $composableBuilder(
      column: $table.lastPageIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$BookGroupsTableTableOrderingComposer get groupId {
    final $$BookGroupsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.bookGroupsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookGroupsTableTableOrderingComposer(
              $db: $db,
              $table: $db.bookGroupsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BooksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTableTable> {
  $$BooksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get bookUrl =>
      $composableBuilder(column: $table.bookUrl, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => column);

  GeneratedColumn<int> get lastReadAt => $composableBuilder(
      column: $table.lastReadAt, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get lastChapterIndex => $composableBuilder(
      column: $table.lastChapterIndex, builder: (column) => column);

  GeneratedColumn<double> get lastScrollOffset => $composableBuilder(
      column: $table.lastScrollOffset, builder: (column) => column);

  GeneratedColumn<int> get lastPageIndex => $composableBuilder(
      column: $table.lastPageIndex, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BookGroupsTableTableAnnotationComposer get groupId {
    final $$BookGroupsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.bookGroupsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookGroupsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.bookGroupsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> chaptersTableRefs<T extends Object>(
      Expression<T> Function($$ChaptersTableTableAnnotationComposer a) f) {
    final $$ChaptersTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chaptersTable,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableTableAnnotationComposer(
              $db: $db,
              $table: $db.chaptersTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> bookmarksTableRefs<T extends Object>(
      Expression<T> Function($$BookmarksTableTableAnnotationComposer a) f) {
    final $$BookmarksTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarksTable,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableTableAnnotationComposer(
              $db: $db,
              $table: $db.bookmarksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> readingSessionsTableRefs<T extends Object>(
      Expression<T> Function($$ReadingSessionsTableTableAnnotationComposer a)
          f) {
    final $$ReadingSessionsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.readingSessionsTable,
            getReferencedColumn: (t) => t.bookId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ReadingSessionsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.readingSessionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$BooksTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BooksTableTable,
    BooksTableData,
    $$BooksTableTableFilterComposer,
    $$BooksTableTableOrderingComposer,
    $$BooksTableTableAnnotationComposer,
    $$BooksTableTableCreateCompanionBuilder,
    $$BooksTableTableUpdateCompanionBuilder,
    (BooksTableData, $$BooksTableTableReferences),
    BooksTableData,
    PrefetchHooks Function(
        {bool groupId,
        bool chaptersTableRefs,
        bool bookmarksTableRefs,
        bool readingSessionsTableRefs})> {
  $$BooksTableTableTableManager(_$AppDatabase db, $BooksTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> author = const Value.absent(),
            Value<String?> coverPath = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> sourceId = const Value.absent(),
            Value<String?> bookUrl = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            Value<int?> lastReadAt = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<int> lastChapterIndex = const Value.absent(),
            Value<double> lastScrollOffset = const Value.absent(),
            Value<int> lastPageIndex = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BooksTableCompanion(
            id: id,
            title: title,
            author: author,
            coverPath: coverPath,
            filePath: filePath,
            sourceId: sourceId,
            bookUrl: bookUrl,
            contentType: contentType,
            groupId: groupId,
            lastReadAt: lastReadAt,
            progress: progress,
            lastChapterIndex: lastChapterIndex,
            lastScrollOffset: lastScrollOffset,
            lastPageIndex: lastPageIndex,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> author = const Value.absent(),
            Value<String?> coverPath = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<String?> sourceId = const Value.absent(),
            Value<String?> bookUrl = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String?> groupId = const Value.absent(),
            Value<int?> lastReadAt = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<int> lastChapterIndex = const Value.absent(),
            Value<double> lastScrollOffset = const Value.absent(),
            Value<int> lastPageIndex = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BooksTableCompanion.insert(
            id: id,
            title: title,
            author: author,
            coverPath: coverPath,
            filePath: filePath,
            sourceId: sourceId,
            bookUrl: bookUrl,
            contentType: contentType,
            groupId: groupId,
            lastReadAt: lastReadAt,
            progress: progress,
            lastChapterIndex: lastChapterIndex,
            lastScrollOffset: lastScrollOffset,
            lastPageIndex: lastPageIndex,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BooksTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {groupId = false,
              chaptersTableRefs = false,
              bookmarksTableRefs = false,
              readingSessionsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (chaptersTableRefs) db.chaptersTable,
                if (bookmarksTableRefs) db.bookmarksTable,
                if (readingSessionsTableRefs) db.readingSessionsTable
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (groupId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.groupId,
                    referencedTable:
                        $$BooksTableTableReferences._groupIdTable(db),
                    referencedColumn:
                        $$BooksTableTableReferences._groupIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chaptersTableRefs)
                    await $_getPrefetchedData<BooksTableData, $BooksTableTable,
                            ChaptersTableData>(
                        currentTable: table,
                        referencedTable: $$BooksTableTableReferences
                            ._chaptersTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BooksTableTableReferences(db, table, p0)
                                .chaptersTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.bookId == item.id),
                        typedResults: items),
                  if (bookmarksTableRefs)
                    await $_getPrefetchedData<BooksTableData, $BooksTableTable,
                            BookmarksTableData>(
                        currentTable: table,
                        referencedTable: $$BooksTableTableReferences
                            ._bookmarksTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BooksTableTableReferences(db, table, p0)
                                .bookmarksTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.bookId == item.id),
                        typedResults: items),
                  if (readingSessionsTableRefs)
                    await $_getPrefetchedData<BooksTableData, $BooksTableTable,
                            ReadingSessionsTableData>(
                        currentTable: table,
                        referencedTable: $$BooksTableTableReferences
                            ._readingSessionsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BooksTableTableReferences(db, table, p0)
                                .readingSessionsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.bookId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BooksTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BooksTableTable,
    BooksTableData,
    $$BooksTableTableFilterComposer,
    $$BooksTableTableOrderingComposer,
    $$BooksTableTableAnnotationComposer,
    $$BooksTableTableCreateCompanionBuilder,
    $$BooksTableTableUpdateCompanionBuilder,
    (BooksTableData, $$BooksTableTableReferences),
    BooksTableData,
    PrefetchHooks Function(
        {bool groupId,
        bool chaptersTableRefs,
        bool bookmarksTableRefs,
        bool readingSessionsTableRefs})>;
typedef $$ChaptersTableTableCreateCompanionBuilder = ChaptersTableCompanion
    Function({
  required String id,
  required String bookId,
  required String title,
  Value<String?> url,
  Value<String?> content,
  required int chapterIndex,
  Value<bool> isCached,
  required int createdAt,
  Value<int> rowid,
});
typedef $$ChaptersTableTableUpdateCompanionBuilder = ChaptersTableCompanion
    Function({
  Value<String> id,
  Value<String> bookId,
  Value<String> title,
  Value<String?> url,
  Value<String?> content,
  Value<int> chapterIndex,
  Value<bool> isCached,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$ChaptersTableTableReferences extends BaseReferences<_$AppDatabase,
    $ChaptersTableTable, ChaptersTableData> {
  $$ChaptersTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $BooksTableTable _bookIdTable(_$AppDatabase db) =>
      db.booksTable.createAlias(
          $_aliasNameGenerator(db.chaptersTable.bookId, db.booksTable.id));

  $$BooksTableTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableTableManager($_db, $_db.booksTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$BookmarksTableTable, List<BookmarksTableData>>
      _bookmarksTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.bookmarksTable,
              aliasName: $_aliasNameGenerator(
                  db.chaptersTable.id, db.bookmarksTable.chapterId));

  $$BookmarksTableTableProcessedTableManager get bookmarksTableRefs {
    final manager = $$BookmarksTableTableTableManager($_db, $_db.bookmarksTable)
        .filter((f) => f.chapterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChaptersTableTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTableTable> {
  $$ChaptersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapterIndex => $composableBuilder(
      column: $table.chapterIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCached => $composableBuilder(
      column: $table.isCached, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$BooksTableTableFilterComposer get bookId {
    final $$BooksTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableFilterComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> bookmarksTableRefs(
      Expression<bool> Function($$BookmarksTableTableFilterComposer f) f) {
    final $$BookmarksTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarksTable,
        getReferencedColumn: (t) => t.chapterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableTableFilterComposer(
              $db: $db,
              $table: $db.bookmarksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChaptersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTableTable> {
  $$ChaptersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapterIndex => $composableBuilder(
      column: $table.chapterIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCached => $composableBuilder(
      column: $table.isCached, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$BooksTableTableOrderingComposer get bookId {
    final $$BooksTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableOrderingComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChaptersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTableTable> {
  $$ChaptersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get chapterIndex => $composableBuilder(
      column: $table.chapterIndex, builder: (column) => column);

  GeneratedColumn<bool> get isCached =>
      $composableBuilder(column: $table.isCached, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BooksTableTableAnnotationComposer get bookId {
    final $$BooksTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableAnnotationComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> bookmarksTableRefs<T extends Object>(
      Expression<T> Function($$BookmarksTableTableAnnotationComposer a) f) {
    final $$BookmarksTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarksTable,
        getReferencedColumn: (t) => t.chapterId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableTableAnnotationComposer(
              $db: $db,
              $table: $db.bookmarksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChaptersTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChaptersTableTable,
    ChaptersTableData,
    $$ChaptersTableTableFilterComposer,
    $$ChaptersTableTableOrderingComposer,
    $$ChaptersTableTableAnnotationComposer,
    $$ChaptersTableTableCreateCompanionBuilder,
    $$ChaptersTableTableUpdateCompanionBuilder,
    (ChaptersTableData, $$ChaptersTableTableReferences),
    ChaptersTableData,
    PrefetchHooks Function({bool bookId, bool bookmarksTableRefs})> {
  $$ChaptersTableTableTableManager(_$AppDatabase db, $ChaptersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<int> chapterIndex = const Value.absent(),
            Value<bool> isCached = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChaptersTableCompanion(
            id: id,
            bookId: bookId,
            title: title,
            url: url,
            content: content,
            chapterIndex: chapterIndex,
            isCached: isCached,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bookId,
            required String title,
            Value<String?> url = const Value.absent(),
            Value<String?> content = const Value.absent(),
            required int chapterIndex,
            Value<bool> isCached = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChaptersTableCompanion.insert(
            id: id,
            bookId: bookId,
            title: title,
            url: url,
            content: content,
            chapterIndex: chapterIndex,
            isCached: isCached,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChaptersTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {bookId = false, bookmarksTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (bookmarksTableRefs) db.bookmarksTable
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (bookId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.bookId,
                    referencedTable:
                        $$ChaptersTableTableReferences._bookIdTable(db),
                    referencedColumn:
                        $$ChaptersTableTableReferences._bookIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bookmarksTableRefs)
                    await $_getPrefetchedData<ChaptersTableData,
                            $ChaptersTableTable, BookmarksTableData>(
                        currentTable: table,
                        referencedTable: $$ChaptersTableTableReferences
                            ._bookmarksTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChaptersTableTableReferences(db, table, p0)
                                .bookmarksTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.chapterId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChaptersTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChaptersTableTable,
    ChaptersTableData,
    $$ChaptersTableTableFilterComposer,
    $$ChaptersTableTableOrderingComposer,
    $$ChaptersTableTableAnnotationComposer,
    $$ChaptersTableTableCreateCompanionBuilder,
    $$ChaptersTableTableUpdateCompanionBuilder,
    (ChaptersTableData, $$ChaptersTableTableReferences),
    ChaptersTableData,
    PrefetchHooks Function({bool bookId, bool bookmarksTableRefs})>;
typedef $$BookmarksTableTableCreateCompanionBuilder = BookmarksTableCompanion
    Function({
  required String id,
  required String bookId,
  required String chapterId,
  required int position,
  Value<int?> startOffset,
  Value<int?> endOffset,
  Value<String?> contentPreview,
  Value<String?> note,
  Value<String?> highlightColor,
  Value<String> type,
  required int createdAt,
  Value<int> rowid,
});
typedef $$BookmarksTableTableUpdateCompanionBuilder = BookmarksTableCompanion
    Function({
  Value<String> id,
  Value<String> bookId,
  Value<String> chapterId,
  Value<int> position,
  Value<int?> startOffset,
  Value<int?> endOffset,
  Value<String?> contentPreview,
  Value<String?> note,
  Value<String?> highlightColor,
  Value<String> type,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$BookmarksTableTableReferences extends BaseReferences<
    _$AppDatabase, $BookmarksTableTable, BookmarksTableData> {
  $$BookmarksTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $BooksTableTable _bookIdTable(_$AppDatabase db) =>
      db.booksTable.createAlias(
          $_aliasNameGenerator(db.bookmarksTable.bookId, db.booksTable.id));

  $$BooksTableTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableTableManager($_db, $_db.booksTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ChaptersTableTable _chapterIdTable(_$AppDatabase db) =>
      db.chaptersTable.createAlias($_aliasNameGenerator(
          db.bookmarksTable.chapterId, db.chaptersTable.id));

  $$ChaptersTableTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<String>('chapter_id')!;

    final manager = $$ChaptersTableTableTableManager($_db, $_db.chaptersTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BookmarksTableTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTableTable> {
  $$BookmarksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startOffset => $composableBuilder(
      column: $table.startOffset, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endOffset => $composableBuilder(
      column: $table.endOffset, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentPreview => $composableBuilder(
      column: $table.contentPreview,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get highlightColor => $composableBuilder(
      column: $table.highlightColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$BooksTableTableFilterComposer get bookId {
    final $$BooksTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableFilterComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ChaptersTableTableFilterComposer get chapterId {
    final $$ChaptersTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chapterId,
        referencedTable: $db.chaptersTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableTableFilterComposer(
              $db: $db,
              $table: $db.chaptersTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTableTable> {
  $$BookmarksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startOffset => $composableBuilder(
      column: $table.startOffset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endOffset => $composableBuilder(
      column: $table.endOffset, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentPreview => $composableBuilder(
      column: $table.contentPreview,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get highlightColor => $composableBuilder(
      column: $table.highlightColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$BooksTableTableOrderingComposer get bookId {
    final $$BooksTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableOrderingComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ChaptersTableTableOrderingComposer get chapterId {
    final $$ChaptersTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chapterId,
        referencedTable: $db.chaptersTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableTableOrderingComposer(
              $db: $db,
              $table: $db.chaptersTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTableTable> {
  $$BookmarksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get startOffset => $composableBuilder(
      column: $table.startOffset, builder: (column) => column);

  GeneratedColumn<int> get endOffset =>
      $composableBuilder(column: $table.endOffset, builder: (column) => column);

  GeneratedColumn<String> get contentPreview => $composableBuilder(
      column: $table.contentPreview, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get highlightColor => $composableBuilder(
      column: $table.highlightColor, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BooksTableTableAnnotationComposer get bookId {
    final $$BooksTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableAnnotationComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ChaptersTableTableAnnotationComposer get chapterId {
    final $$ChaptersTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.chapterId,
        referencedTable: $db.chaptersTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableTableAnnotationComposer(
              $db: $db,
              $table: $db.chaptersTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookmarksTableTable,
    BookmarksTableData,
    $$BookmarksTableTableFilterComposer,
    $$BookmarksTableTableOrderingComposer,
    $$BookmarksTableTableAnnotationComposer,
    $$BookmarksTableTableCreateCompanionBuilder,
    $$BookmarksTableTableUpdateCompanionBuilder,
    (BookmarksTableData, $$BookmarksTableTableReferences),
    BookmarksTableData,
    PrefetchHooks Function({bool bookId, bool chapterId})> {
  $$BookmarksTableTableTableManager(
      _$AppDatabase db, $BookmarksTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<String> chapterId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int?> startOffset = const Value.absent(),
            Value<int?> endOffset = const Value.absent(),
            Value<String?> contentPreview = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> highlightColor = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksTableCompanion(
            id: id,
            bookId: bookId,
            chapterId: chapterId,
            position: position,
            startOffset: startOffset,
            endOffset: endOffset,
            contentPreview: contentPreview,
            note: note,
            highlightColor: highlightColor,
            type: type,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bookId,
            required String chapterId,
            required int position,
            Value<int?> startOffset = const Value.absent(),
            Value<int?> endOffset = const Value.absent(),
            Value<String?> contentPreview = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> highlightColor = const Value.absent(),
            Value<String> type = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksTableCompanion.insert(
            id: id,
            bookId: bookId,
            chapterId: chapterId,
            position: position,
            startOffset: startOffset,
            endOffset: endOffset,
            contentPreview: contentPreview,
            note: note,
            highlightColor: highlightColor,
            type: type,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BookmarksTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({bookId = false, chapterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (bookId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.bookId,
                    referencedTable:
                        $$BookmarksTableTableReferences._bookIdTable(db),
                    referencedColumn:
                        $$BookmarksTableTableReferences._bookIdTable(db).id,
                  ) as T;
                }
                if (chapterId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.chapterId,
                    referencedTable:
                        $$BookmarksTableTableReferences._chapterIdTable(db),
                    referencedColumn:
                        $$BookmarksTableTableReferences._chapterIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BookmarksTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookmarksTableTable,
    BookmarksTableData,
    $$BookmarksTableTableFilterComposer,
    $$BookmarksTableTableOrderingComposer,
    $$BookmarksTableTableAnnotationComposer,
    $$BookmarksTableTableCreateCompanionBuilder,
    $$BookmarksTableTableUpdateCompanionBuilder,
    (BookmarksTableData, $$BookmarksTableTableReferences),
    BookmarksTableData,
    PrefetchHooks Function({bool bookId, bool chapterId})>;
typedef $$BookSourcesTableTableCreateCompanionBuilder
    = BookSourcesTableCompanion Function({
  required String id,
  required String name,
  required String host,
  Value<String> contentType,
  Value<bool> enabled,
  Value<int> weight,
  required String ruleJson,
  Value<String> status,
  Value<int?> lastTestedAt,
  Value<String?> groupName,
  Value<bool> builtIn,
  required int createdAt,
  Value<int> rowid,
});
typedef $$BookSourcesTableTableUpdateCompanionBuilder
    = BookSourcesTableCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> host,
  Value<String> contentType,
  Value<bool> enabled,
  Value<int> weight,
  Value<String> ruleJson,
  Value<String> status,
  Value<int?> lastTestedAt,
  Value<String?> groupName,
  Value<bool> builtIn,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$BookSourcesTableTableFilterComposer
    extends Composer<_$AppDatabase, $BookSourcesTableTable> {
  $$BookSourcesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get host => $composableBuilder(
      column: $table.host, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ruleJson => $composableBuilder(
      column: $table.ruleJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastTestedAt => $composableBuilder(
      column: $table.lastTestedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get builtIn => $composableBuilder(
      column: $table.builtIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$BookSourcesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BookSourcesTableTable> {
  $$BookSourcesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get host => $composableBuilder(
      column: $table.host, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(
      column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ruleJson => $composableBuilder(
      column: $table.ruleJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastTestedAt => $composableBuilder(
      column: $table.lastTestedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get builtIn => $composableBuilder(
      column: $table.builtIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BookSourcesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookSourcesTableTable> {
  $$BookSourcesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<String> get ruleJson =>
      $composableBuilder(column: $table.ruleJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get lastTestedAt => $composableBuilder(
      column: $table.lastTestedAt, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<bool> get builtIn =>
      $composableBuilder(column: $table.builtIn, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookSourcesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookSourcesTableTable,
    BookSourcesTableData,
    $$BookSourcesTableTableFilterComposer,
    $$BookSourcesTableTableOrderingComposer,
    $$BookSourcesTableTableAnnotationComposer,
    $$BookSourcesTableTableCreateCompanionBuilder,
    $$BookSourcesTableTableUpdateCompanionBuilder,
    (
      BookSourcesTableData,
      BaseReferences<_$AppDatabase, $BookSourcesTableTable,
          BookSourcesTableData>
    ),
    BookSourcesTableData,
    PrefetchHooks Function()> {
  $$BookSourcesTableTableTableManager(
      _$AppDatabase db, $BookSourcesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookSourcesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookSourcesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookSourcesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> host = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<int> weight = const Value.absent(),
            Value<String> ruleJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> lastTestedAt = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
            Value<bool> builtIn = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookSourcesTableCompanion(
            id: id,
            name: name,
            host: host,
            contentType: contentType,
            enabled: enabled,
            weight: weight,
            ruleJson: ruleJson,
            status: status,
            lastTestedAt: lastTestedAt,
            groupName: groupName,
            builtIn: builtIn,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String host,
            Value<String> contentType = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<int> weight = const Value.absent(),
            required String ruleJson,
            Value<String> status = const Value.absent(),
            Value<int?> lastTestedAt = const Value.absent(),
            Value<String?> groupName = const Value.absent(),
            Value<bool> builtIn = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BookSourcesTableCompanion.insert(
            id: id,
            name: name,
            host: host,
            contentType: contentType,
            enabled: enabled,
            weight: weight,
            ruleJson: ruleJson,
            status: status,
            lastTestedAt: lastTestedAt,
            groupName: groupName,
            builtIn: builtIn,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BookSourcesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookSourcesTableTable,
    BookSourcesTableData,
    $$BookSourcesTableTableFilterComposer,
    $$BookSourcesTableTableOrderingComposer,
    $$BookSourcesTableTableAnnotationComposer,
    $$BookSourcesTableTableCreateCompanionBuilder,
    $$BookSourcesTableTableUpdateCompanionBuilder,
    (
      BookSourcesTableData,
      BaseReferences<_$AppDatabase, $BookSourcesTableTable,
          BookSourcesTableData>
    ),
    BookSourcesTableData,
    PrefetchHooks Function()>;
typedef $$ReadingSessionsTableTableCreateCompanionBuilder
    = ReadingSessionsTableCompanion Function({
  required String id,
  required String bookId,
  required int startTime,
  required int endTime,
  required int durationSeconds,
  Value<int> wordsRead,
  Value<int> rowid,
});
typedef $$ReadingSessionsTableTableUpdateCompanionBuilder
    = ReadingSessionsTableCompanion Function({
  Value<String> id,
  Value<String> bookId,
  Value<int> startTime,
  Value<int> endTime,
  Value<int> durationSeconds,
  Value<int> wordsRead,
  Value<int> rowid,
});

final class $$ReadingSessionsTableTableReferences extends BaseReferences<
    _$AppDatabase, $ReadingSessionsTableTable, ReadingSessionsTableData> {
  $$ReadingSessionsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $BooksTableTable _bookIdTable(_$AppDatabase db) =>
      db.booksTable.createAlias($_aliasNameGenerator(
          db.readingSessionsTable.bookId, db.booksTable.id));

  $$BooksTableTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableTableManager($_db, $_db.booksTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReadingSessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTableTable> {
  $$ReadingSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wordsRead => $composableBuilder(
      column: $table.wordsRead, builder: (column) => ColumnFilters(column));

  $$BooksTableTableFilterComposer get bookId {
    final $$BooksTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableFilterComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingSessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTableTable> {
  $$ReadingSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endTime => $composableBuilder(
      column: $table.endTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wordsRead => $composableBuilder(
      column: $table.wordsRead, builder: (column) => ColumnOrderings(column));

  $$BooksTableTableOrderingComposer get bookId {
    final $$BooksTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableOrderingComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingSessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTableTable> {
  $$ReadingSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get wordsRead =>
      $composableBuilder(column: $table.wordsRead, builder: (column) => column);

  $$BooksTableTableAnnotationComposer get bookId {
    final $$BooksTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.booksTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableTableAnnotationComposer(
              $db: $db,
              $table: $db.booksTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingSessionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReadingSessionsTableTable,
    ReadingSessionsTableData,
    $$ReadingSessionsTableTableFilterComposer,
    $$ReadingSessionsTableTableOrderingComposer,
    $$ReadingSessionsTableTableAnnotationComposer,
    $$ReadingSessionsTableTableCreateCompanionBuilder,
    $$ReadingSessionsTableTableUpdateCompanionBuilder,
    (ReadingSessionsTableData, $$ReadingSessionsTableTableReferences),
    ReadingSessionsTableData,
    PrefetchHooks Function({bool bookId})> {
  $$ReadingSessionsTableTableTableManager(
      _$AppDatabase db, $ReadingSessionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<int> startTime = const Value.absent(),
            Value<int> endTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> wordsRead = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadingSessionsTableCompanion(
            id: id,
            bookId: bookId,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            wordsRead: wordsRead,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bookId,
            required int startTime,
            required int endTime,
            required int durationSeconds,
            Value<int> wordsRead = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadingSessionsTableCompanion.insert(
            id: id,
            bookId: bookId,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            wordsRead: wordsRead,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReadingSessionsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (bookId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.bookId,
                    referencedTable:
                        $$ReadingSessionsTableTableReferences._bookIdTable(db),
                    referencedColumn: $$ReadingSessionsTableTableReferences
                        ._bookIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReadingSessionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ReadingSessionsTableTable,
        ReadingSessionsTableData,
        $$ReadingSessionsTableTableFilterComposer,
        $$ReadingSessionsTableTableOrderingComposer,
        $$ReadingSessionsTableTableAnnotationComposer,
        $$ReadingSessionsTableTableCreateCompanionBuilder,
        $$ReadingSessionsTableTableUpdateCompanionBuilder,
        (ReadingSessionsTableData, $$ReadingSessionsTableTableReferences),
        ReadingSessionsTableData,
        PrefetchHooks Function({bool bookId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BookGroupsTableTableTableManager get bookGroupsTable =>
      $$BookGroupsTableTableTableManager(_db, _db.bookGroupsTable);
  $$BooksTableTableTableManager get booksTable =>
      $$BooksTableTableTableManager(_db, _db.booksTable);
  $$ChaptersTableTableTableManager get chaptersTable =>
      $$ChaptersTableTableTableManager(_db, _db.chaptersTable);
  $$BookmarksTableTableTableManager get bookmarksTable =>
      $$BookmarksTableTableTableManager(_db, _db.bookmarksTable);
  $$BookSourcesTableTableTableManager get bookSourcesTable =>
      $$BookSourcesTableTableTableManager(_db, _db.bookSourcesTable);
  $$ReadingSessionsTableTableTableManager get readingSessionsTable =>
      $$ReadingSessionsTableTableTableManager(_db, _db.readingSessionsTable);
}
