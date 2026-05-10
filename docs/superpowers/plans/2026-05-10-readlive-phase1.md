# ReadLive Phase 1: 骨架 + 本地阅读 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a working novel reader app with local file import (TXT/EPUB), bookshelf management, basic reader with page turning, progress saving, and dark/light theme support.

**Architecture:** Clean Architecture + Feature-first. Each feature has data/domain/presentation layers. Riverpod for state management, drift for SQLite, go_router for navigation.

**Tech Stack:** Flutter 3.x, Riverpod 2.x, drift, go_router, epubx, file_picker, uuid

---

## File Structure

```
D:/ReadLive/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   ├── app_database.g.dart
│   │   │   ├── tables.dart
│   │   │   └── daos/
│   │   │       ├── book_dao.dart
│   │   │       └── book_dao.g.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   └── utils/
│   │       └── uuid_generator.dart
│   └── features/
│       ├── bookshelf/
│       │   ├── data/
│       │   │   └── book_repository.dart
│       │   ├── domain/
│       │   │   └── book_entity.dart
│       │   └── presentation/
│       │       ├── bookshelf_page.dart
│       │       ├── bookshelf_provider.dart
│       │       └── widgets/
│       │           └── book_card.dart
│       ├── reader/
│       │   ├── data/
│       │   │   ├── txt_parser.dart
│       │   │   └── epub_parser.dart
│       │   ├── domain/
│       │   │   ├── chapter_entity.dart
│       │   │   └── page_content.dart
│       │   └── presentation/
│       │       ├── reader_page.dart
│       │       ├── reader_provider.dart
│       │       └── widgets/
│       │           ├── text_content_view.dart
│       │           ├── reader_toolbar.dart
│       │           └── page_slider.dart
│       ├── settings/
│       │   ├── data/
│       │   │   └── settings_repository.dart
│       │   ├── domain/
│       │   │   └── reading_settings.dart
│       │   └── presentation/
│       │       ├── settings_page.dart
│       │       └── settings_provider.dart
│       └── profile/
│           └── presentation/
│               └── profile_page.dart
├── test/
│   ├── core/
│   │   └── database/
│   │       └── app_database_test.dart
│   ├── features/
│   │   ├── bookshelf/
│   │   │   └── data/
│   │   │       └── book_repository_test.dart
│   │   ├── reader/
│   │   │   └── data/
│   │   │       ├── txt_parser_test.dart
│   │   │       └── epub_parser_test.dart
│   │   └── settings/
│   │       └── data/
│   │           └── settings_repository_test.dart
│   └── widgets/
│       └── bookshelf_page_test.dart
└── docs/
    └── superpowers/
        ├── specs/
        │   └── 2026-05-10-readlive-design.md
        └── plans/
            └── 2026-05-10-readlive-phase1.md
```

---

### Task 1: Flutter Project Scaffolding

**Files:**
- Create: `D:/ReadLive/pubspec.yaml`
- Create: `D:/ReadLive/lib/main.dart`
- Create: `D:/ReadLive/lib/app.dart`
- Create: `D:/ReadLive/analysis_options.yaml`

- [ ] **Step 1: Create Flutter project**

```bash
cd D:/ReadLive
flutter create --org com.readlive --project-name readlive --platforms android,ios,windows,macos,linux .
```

Expected: Project created with default template.

- [ ] **Step 2: Replace pubspec.yaml with project dependencies**

```yaml
name: readlive
description: A local-first novel reader app.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  drift: ^2.22.1
  sqlite3_flutter_libs: ^0.5.28
  go_router: ^14.6.2
  epubx: ^3.0.2
  file_picker: ^8.1.7
  path_provider: ^2.1.5
  path: ^1.9.1
  uuid: ^4.5.1
  intl: ^0.19.0
  shared_preferences: ^2.3.4
  json_annotation: ^4.9.0
  sqlite3: ^2.7.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.14
  riverpod_generator: ^2.6.2
  drift_dev: ^2.22.1
  json_serializable: ^6.9.2
  freezed_annotation: ^2.4.4
  freezed: ^2.5.7
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Install dependencies**

```bash
cd D:/ReadLive
flutter pub get
```

Expected: All dependencies resolved successfully.

- [ ] **Step 4: Create main.dart entry point**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ReadLiveApp(),
    ),
  );
}
```

- [ ] **Step 5: Create app.dart skeleton**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadLiveApp extends ConsumerWidget {
  const ReadLiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ReadLive',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B6914),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('ReadLive'),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Verify app builds**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors.

- [ ] **Step 7: Commit**

```bash
git init
git add -A
git commit -m "feat: initial Flutter project scaffolding with dependencies"
```

---

### Task 2: Core Database — Tables

**Files:**
- Create: `lib/core/database/tables.dart`
- Create: `lib/core/database/app_database.dart`
- Test: `test/core/database/app_database_test.dart`

- [ ] **Step 1: Write failing test for database creation**

```dart
// test/core/database/app_database_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:readlive/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('database can be created and is empty', () async {
    final books = await db.select(db.booksTable).get();
    expect(books, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd D:/ReadLive
flutter test test/core/database/app_database_test.dart
```

Expected: FAIL — `app_database.dart` does not exist.

- [ ] **Step 3: Create tables.dart**

```dart
// lib/core/database/tables.dart
import 'package:drift/drift.dart';

class BooksTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get author => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get bookUrl => text().nullable()();
  TextColumn get contentType => text().withDefault(const Constant('novel'))();
  IntColumn get lastReadAt => integer().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChaptersTable extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(BooksTable, #id)();
  TextColumn get title => text()();
  TextColumn get url => text().nullable()();
  TextColumn get content => text().nullable()();
  IntColumn get chapterIndex => integer()();
  BoolColumn get isCached => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class BookmarksTable extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().references(BooksTable, #id)();
  TextColumn get chapterId => text().references(ChaptersTable, #id)();
  IntColumn get position => integer()();
  TextColumn get contentPreview => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get highlightColor => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('bookmark'))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 4: Create app_database.dart**

```dart
// lib/core/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [BooksTable, ChaptersTable, BookmarksTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // Books CRUD
  Future<List<BooksTableData>> getAllBooks() => select(booksTable).get();

  Stream<List<BooksTableData>> watchAllBooks() => select(booksTable).watch();

  Future<BooksTableData?> getBookById(String id) =>
      (select(booksTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertBook(BooksTableCompanion entry) =>
      into(booksTable).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateBook(BooksTableCompanion entry) =>
      update(booksTable).replace(entry);

  Future<int> deleteBook(String id) =>
      (delete(booksTable)..where((t) => t.id.equals(id))).go();

  // Chapters CRUD
  Future<List<ChaptersTableData>> getChaptersByBook(String bookId) =>
      (select(chaptersTable)
            ..where((t) => t.bookId.equals(bookId))
            ..orderBy([(t) => OrderingTerm.asc(t.chapterIndex)]))
          .get();

  Stream<List<ChaptersTableData>> watchChaptersByBook(String bookId) =>
      (select(chaptersTable)
            ..where((t) => t.bookId.equals(bookId))
            ..orderBy([(t) => OrderingTerm.asc(t.chapterIndex)]))
          .watch();

  Future<int> insertChapter(ChaptersTableCompanion entry) =>
      into(chaptersTable).insert(entry, mode: InsertMode.insertOrReplace);

  Future<int> insertChapters(List<ChaptersTableCompanion> entries) =>
      batch((batch) => batch.insertAll(chaptersTable, entries,
          mode: InsertMode.insertOrReplace));

  Future<int> deleteChaptersByBook(String bookId) =>
      (delete(chaptersTable)..where((t) => t.bookId.equals(bookId))).go();

  // Bookmarks CRUD
  Future<List<BookmarksTableData>> getBookmarksByBook(String bookId) =>
      (select(bookmarksTable)..where((t) => t.bookId.equals(bookId))).get();

  Future<int> insertBookmark(BookmarksTableCompanion entry) =>
      into(bookmarksTable).insert(entry);

  Future<int> deleteBookmark(String id) =>
      (delete(bookmarksTable)..where((t) => t.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'readlive.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 4b: Run build_runner to generate code**

```bash
cd D:/ReadLive
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_database.g.dart` generated.

- [ ] **Step 5: Run test to verify it passes**

```bash
cd D:/ReadLive
flutter test test/core/database/app_database_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/ test/core/database/
git commit -m "feat: core database with books, chapters, bookmarks tables"
```

---

### Task 3: Core — Theme System

**Files:**
- Create: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Create app_theme.dart**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF8B6914);

  static final lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F5F0),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  static final darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  // Reading background presets
  static const readingBackgrounds = [
    Color(0xFFF5F0E6), // Warm white
    Color(0xFFF5E6C8), // Cream yellow
    Color(0xFFE8F0E4), // Light green
    Color(0xFF2C2C2C), // Dark gray
    Color(0xFF1A1A1A), // Pure black
  ];

  static const readingTextColors = [
    Color(0xFF333333), // Dark text (for light backgrounds)
    Color(0xFFE0E0E0), // Light text (for dark backgrounds)
  ];
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/core/theme/
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/
git commit -m "feat: theme system with light/dark mode and reading background presets"
```

---

### Task 4: Core — Router

**Files:**
- Create: `lib/core/router/app_router.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Create app_router.dart**

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:readlive/features/profile/presentation/profile_page.dart';
import 'package:readlive/features/reader/presentation/reader_page.dart';
import 'package:readlive/features/settings/presentation/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BookshelfPage(contentType: 'novel'),
          ),
        ),
        GoRoute(
          path: '/manga',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BookshelfPage(contentType: 'manga'),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/reader/:bookId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ReaderPage(
        bookId: state.pathParameters['bookId']!,
      ),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: '书架',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/manga')) return 0;
    if (location.startsWith('/profile')) return 1;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/profile');
    }
  }
}
```

- [ ] **Step 2: Update app.dart to use router**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ReadLiveApp extends ConsumerWidget {
  const ReadLiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ReadLive',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
```

- [ ] **Step 3: Create placeholder pages for routing to work**

Create minimal placeholder files so the router compiles:

```dart
// lib/features/bookshelf/presentation/bookshelf_page.dart
import 'package:flutter/material.dart';

class BookshelfPage extends StatelessWidget {
  final String contentType;
  const BookshelfPage({super.key, required this.contentType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contentType == 'manga' ? '漫画' : '小说')),
      body: const Center(child: Text('书架')),
    );
  }
}
```

```dart
// lib/features/profile/presentation/profile_page.dart
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: const Center(child: Text('个人中心')),
    );
  }
}
```

```dart
// lib/features/reader/presentation/reader_page.dart
import 'package:flutter/material.dart';

class ReaderPage extends StatelessWidget {
  final String bookId;
  const ReaderPage({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('阅读器: $bookId')),
    );
  }
}
```

```dart
// lib/features/settings/presentation/settings_page.dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const Center(child: Text('设置')),
    );
  }
}
```

- [ ] **Step 4: Verify app builds and runs**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/ lib/core/theme/ lib/app.dart lib/features/
git commit -m "feat: go_router navigation with bookshelf/profile shell and reader route"
```

---

### Task 5: Bookshelf — Data Layer

**Files:**
- Create: `lib/features/bookshelf/data/book_repository.dart`
- Create: `lib/features/bookshelf/domain/book_entity.dart`
- Test: `test/features/bookshelf/data/book_repository_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/features/bookshelf/data/book_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late BookRepository repo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    repo = BookRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addBook and getAllBooks', () async {
    final book = await repo.addBook(
      title: 'Test Book',
      author: 'Author',
      filePath: '/path/to/file.txt',
      contentType: 'novel',
    );
    expect(book.title, 'Test Book');

    final books = await repo.getAllBooks();
    expect(books.length, 1);
    expect(books.first.title, 'Test Book');
  });

  test('deleteBook removes book and its chapters', () async {
    final book = await repo.addBook(
      title: 'To Delete',
      filePath: '/path.txt',
      contentType: 'novel',
    );
    await repo.deleteBook(book.id);
    final books = await repo.getAllBooks();
    expect(books, isEmpty);
  });

  test('updateProgress', () async {
    final book = await repo.addBook(
      title: 'Progress Book',
      filePath: '/path.txt',
      contentType: 'novel',
    );
    await repo.updateProgress(book.id, 0.5);
    final updated = await repo.getBookById(book.id);
    expect(updated!.progress, 0.5);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd D:/ReadLive
flutter test test/features/bookshelf/data/book_repository_test.dart
```

Expected: FAIL — `book_repository.dart` does not exist.

- [ ] **Step 3: Create book_entity.dart**

```dart
// lib/features/bookshelf/domain/book_entity.dart
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
```

- [ ] **Step 4: Create book_repository.dart**

```dart
// lib/features/bookshelf/data/book_repository.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

class BookRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  BookRepository(this._db);

  Future<List<BookEntity>> getAllBooks() async {
    final data = await _db.getAllBooks();
    return data.map(BookEntity.fromData).toList();
  }

  Stream<List<BookEntity>> watchAllBooks() {
    return _db.watchAllBooks().map(
          (list) => list.map(BookEntity.fromData).toList(),
        );
  }

  Future<BookEntity?> getBookById(String id) async {
    final data = await _db.getBookById(id);
    return data != null ? BookEntity.fromData(data) : null;
  }

  Future<BookEntity> addBook({
    required String title,
    String? author,
    String? coverPath,
    String? filePath,
    String? sourceId,
    String? bookUrl,
    required String contentType,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final companion = BooksTableCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      coverPath: Value(coverPath),
      filePath: Value(filePath),
      sourceId: Value(sourceId),
      bookUrl: Value(bookUrl),
      contentType: Value(contentType),
      progress: const Value(0.0),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await _db.insertBook(companion);
    return (await getBookById(id))!;
  }

  Future<void> deleteBook(String id) async {
    await _db.deleteChaptersByBook(id);
    await _db.deleteBook(id);
  }

  Future<void> updateProgress(String bookId, double progress) async {
    final book = await _db.getBookById(bookId);
    if (book == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.updateBook(
      book.toCompanion(true).copyWith(
            progress: Value(progress),
            lastReadAt: Value(now),
            updatedAt: Value(now),
          ),
    );
  }

  Future<void> insertChapters(
    String bookId,
    List<ChaptersTableCompanion> chapters,
  ) async {
    await _db.deleteChaptersByBook(bookId);
    await _db.insertChapters(chapters);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd D:/ReadLive
flutter test test/features/bookshelf/data/book_repository_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/bookshelf/ test/features/bookshelf/
git commit -m "feat: book repository with CRUD and progress tracking"
```

---

### Task 6: Bookshelf — State Management (Riverpod)

**Files:**
- Create: `lib/features/bookshelf/presentation/bookshelf_provider.dart`

- [ ] **Step 1: Create bookshelf_provider.dart**

```dart
// lib/features/bookshelf/presentation/bookshelf_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BookRepository(db);
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final booksStreamProvider = StreamProvider<List<BookEntity>>((ref) {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.watchAllBooks();
});

final filteredBooksProvider = Provider.family<AsyncValue<List<BookEntity>>, String>((ref, contentType) {
  final booksAsync = ref.watch(booksStreamProvider);
  return booksAsync.whenData(
    (books) => books.where((b) => b.contentType == contentType).toList(),
  );
});

class BookshelfActions {
  final BookRepository _repo;
  BookshelfActions(this._repo);

  Future<void> deleteBook(String id) => _repo.deleteBook(id);
  Future<void> updateProgress(String id, double progress) =>
      _repo.updateProgress(id, progress);
}

final bookshelfActionsProvider = Provider<BookshelfActions>((ref) {
  final repo = ref.watch(bookRepositoryProvider);
  return BookshelfActions(repo);
});
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/features/bookshelf/presentation/bookshelf_provider.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/bookshelf/presentation/bookshelf_provider.dart
git commit -m "feat: bookshelf Riverpod providers with filtering by content type"
```

---

### Task 7: Bookshelf — UI Page

**Files:**
- Modify: `lib/features/bookshelf/presentation/bookshelf_page.dart`
- Create: `lib/features/bookshelf/presentation/widgets/book_card.dart`

- [ ] **Step 1: Create book_card.dart**

```dart
// lib/features/bookshelf/presentation/widgets/book_card.dart
import 'package:flutter/material.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

class BookCard extends StatelessWidget {
  final BookEntity book;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.primaryContainer,
                child: book.coverPath != null
                    ? Image.asset(book.coverPath!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          book.title.substring(0, book.title.length.clamp(0, 4)),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (book.author != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: book.progress,
                    minHeight: 2,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update bookshelf_page.dart with full implementation**

```dart
// lib/features/bookshelf/presentation/bookshelf_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/bookshelf/presentation/widgets/book_card.dart';
import 'package:readlive/features/reader/data/txt_parser.dart';
import 'package:readlive/features/reader/data/epub_parser.dart';

class BookshelfPage extends ConsumerStatefulWidget {
  final String contentType;
  const BookshelfPage({super.key, required this.contentType});

  @override
  ConsumerState<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends ConsumerState<BookshelfPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.contentType == 'manga' ? 1 : 0;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Navigation handled by onTap on TabBar instead
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _tabController,
          onTap: (index) {
            final path = index == 0 ? '/' : '/manga';
            context.go(path);
          },
          tabs: const [
            Tab(text: '小说'),
            Tab(text: '漫画'),
          ],
          isScrollable: true,
          tabAlignment: TabAlignment.center,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Phase 2: search
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _importFile,
          ),
        ],
      ),
      body: _BookList(contentType: widget.contentType),
    );
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'epub'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final filePath = file.path;
    if (filePath == null) return;

    final repo = ref.read(bookRepositoryProvider);

    if (filePath.toLowerCase().endsWith('.txt')) {
      final parser = TxtParser();
      final book = await parser.importTxtFile(filePath, repo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入: ${book.title}')),
        );
      }
    } else if (filePath.toLowerCase().endsWith('.epub')) {
      final parser = EpubParser();
      final book = await parser.importEpubFile(filePath, repo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入: ${book.title}')),
        );
      }
    }
  }
}

class _BookList extends ConsumerWidget {
  final String contentType;
  const _BookList({required this.contentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(filteredBooksProvider(contentType));

    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined,
                    size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text('暂无书籍', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('点击右上角 + 导入书籍',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCard(
              book: book,
              onTap: () => context.push('/reader/${book.id}'),
              onLongPress: () => _showDeleteDialog(context, ref, book.id),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String bookId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除书籍'),
        content: const Text('确定要删除这本书吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(bookshelfActionsProvider).deleteBook(bookId);
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors. (Note: TxtParser and EpubParser references will fail until Task 8/9)

- [ ] **Step 4: Commit**

```bash
git add lib/features/bookshelf/
git commit -m "feat: bookshelf page with grid view, novel/manga tabs, file import"
```

---

### Task 8: Reader — TXT Parser

**Files:**
- Create: `lib/features/reader/data/txt_parser.dart`
- Create: `lib/features/reader/domain/chapter_entity.dart`
- Test: `test/features/reader/data/txt_parser_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/features/reader/data/txt_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/reader/data/txt_parser.dart';

void main() {
  final parser = TxtParser();

  test('splitChapters detects chapter headings', () {
    const text = '''
第一章 开始
这是第一章的内容。

第二章 发展
这是第二章的内容。

第三章 高潮
这是第三章的内容。
''';
    final chapters = parser.splitChapters(text);
    expect(chapters.length, 3);
    expect(chapters[0].title, '第一章 开始');
    expect(chapters[1].title, '第二章 发展');
    expect(chapters[2].title, '第三章 高潮');
    expect(chapters[0].content, contains('这是第一章'));
  });

  test('splitChapters handles text without chapters', () {
    const text = '这是一段很长的文本内容，没有章节标记。';
    final chapters = parser.splitChapters(text);
    expect(chapters.length, 1);
    expect(chapters[0].title, '开始');
  });

  test('splitChapters handles numeric chapter numbers', () {
    const text = '''
第1章 开始
内容1

第2章 发展
内容2
''';
    final chapters = parser.splitChapters(text);
    expect(chapters.length, 2);
    expect(chapters[0].title, '第1章 开始');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd D:/ReadLive
flutter test test/features/reader/data/txt_parser_test.dart
```

Expected: FAIL — `txt_parser.dart` does not exist.

- [ ] **Step 3: Create chapter_entity.dart**

```dart
// lib/features/reader/domain/chapter_entity.dart
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
```

- [ ] **Step 4: Create txt_parser.dart**

```dart
// lib/features/reader/data/txt_parser.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/reader/domain/chapter_entity.dart';

class TxtParser {
  static const _uuid = Uuid();
  static final _chapterPattern = RegExp(
    r'^第[零一二三四五六七八九十百千万\d]+[章节回卷集部篇].*$',
    multiLine: true,
  );

  List<ParsedChapter> splitChapters(String text) {
    final matches = _chapterPattern.allMatches(text).toList();

    if (matches.isEmpty) {
      return [ParsedChapter(title: '开始', content: text.trim())];
    }

    final chapters = <ParsedChapter>[];

    // Content before first chapter
    final preamble = text.substring(0, matches.first.start).trim();
    if (preamble.isNotEmpty) {
      chapters.add(ParsedChapter(title: '序章', content: preamble));
    }

    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final block = text.substring(start, end).trim();

      // Extract title from first line
      final newlineIndex = block.indexOf('\n');
      final title = newlineIndex > 0
          ? block.substring(0, newlineIndex).trim()
          : block.trim();
      final content = newlineIndex > 0
          ? block.substring(newlineIndex + 1).trim()
          : '';

      chapters.add(ParsedChapter(title: title, content: content));
    }

    return chapters;
  }

  Future<BookEntity> importTxtFile(String filePath, BookRepository repo) async {
    final file = File(filePath);
    final text = await file.readAsString();
    final fileName = filePath.split(Platform.pathSeparator).last;
    final title = fileName.replaceAll(RegExp(r'\.txt$', caseSensitive: false), '');

    final book = await repo.addBook(
      title: title,
      filePath: filePath,
      contentType: 'novel',
    );

    final parsedChapters = splitChapters(text);
    final now = DateTime.now().millisecondsSinceEpoch;

    final chapterEntries = <ChaptersTableCompanion>[];
    for (var i = 0; i < parsedChapters.length; i++) {
      final ch = parsedChapters[i];
      chapterEntries.add(ChaptersTableCompanion(
        id: Value(_uuid.v4()),
        bookId: Value(book.id),
        title: Value(ch.title),
        content: Value(ch.content),
        chapterIndex: Value(i),
        isCached: const Value(true),
        createdAt: Value(now),
      ));
    }

    await repo.insertChapters(book.id, chapterEntries);
    return book;
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd D:/ReadLive
flutter test test/features/reader/data/txt_parser_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/reader/ test/features/reader/
git commit -m "feat: TXT parser with chapter detection and file import"
```

---

### Task 9: Reader — EPUB Parser

**Files:**
- Create: `lib/features/reader/data/epub_parser.dart`
- Test: `test/features/reader/data/epub_parser_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/features/reader/data/epub_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/reader/data/epub_parser.dart';

void main() {
  test('EpubParser class exists and can be instantiated', () {
    final parser = EpubParser();
    expect(parser, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd D:/ReadLive
flutter test test/features/reader/data/epub_parser_test.dart
```

Expected: FAIL — `epub_parser.dart` does not exist.

- [ ] **Step 3: Create epub_parser.dart**

```dart
// lib/features/reader/data/epub_parser.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:epubx/epubx.dart';
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
    final bytes = await file.readAsBytes();
    final epub = EpubReader.readBytes(bytes);

    final title = epub.Title ?? filePath.split(Platform.pathSeparator).last;
    final author = epub.Author;

    final book = await repo.addBook(
      title: title,
      author: author,
      filePath: filePath,
      contentType: 'novel',
    );

    // Extract chapters from EPUB
    final chapters = epub.Chapters ?? [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final chapterEntries = <ChaptersTableCompanion>[];

    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterTitle = chapter.Title ?? '第${i + 1}章';
      // Extract text content from HTML
      final content = _extractTextFromHtml(chapter.HtmlContent ?? '');

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

  String _extractTextFromHtml(String html) {
    // Simple HTML tag removal for basic text extraction
    // This will be enhanced in Phase 3 with proper rendering
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd D:/ReadLive
flutter test test/features/reader/data/epub_parser_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reader/data/epub_parser.dart test/features/reader/data/epub_parser_test.dart
git commit -m "feat: EPUB parser with chapter extraction and file import"
```

---

### Task 10: Reader — Pagination Engine

**Files:**
- Create: `lib/features/reader/domain/page_content.dart`
- Create: `lib/features/reader/data/pagination_engine.dart`
- Test: `test/features/reader/data/pagination_engine_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/features/reader/data/pagination_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:readlive/features/reader/data/pagination_engine.dart';

void main() {
  test('paginate splits text into pages based on dimensions', () {
    const text = '这是第一段内容。\n\n这是第二段内容。\n\n这是第三段内容。';
    final engine = PaginationEngine(
      fontSize: 18,
      lineHeight: 1.8,
      paragraphSpacing: 16,
      screenWidth: 360,
      screenHeight: 640,
      padding: const EdgeInsets.all(16),
    );
    final pages = engine.paginate(text);
    expect(pages, isNotEmpty);
    expect(pages.first.text, isNotEmpty);
  });

  test('paginate handles empty text', () {
    final engine = PaginationEngine(
      fontSize: 18,
      lineHeight: 1.8,
      paragraphSpacing: 16,
      screenWidth: 360,
      screenHeight: 640,
      padding: const EdgeInsets.all(16),
    );
    final pages = engine.paginate('');
    expect(pages.length, 1);
    expect(pages.first.text, '');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd D:/ReadLive
flutter test test/features/reader/data/pagination_engine_test.dart
```

Expected: FAIL — `pagination_engine.dart` does not exist.

- [ ] **Step 3: Create page_content.dart**

```dart
// lib/features/reader/domain/page_content.dart
class PageContent {
  final String text;
  final int startIndex;
  final int endIndex;

  const PageContent({
    required this.text,
    required this.startIndex,
    required this.endIndex,
  });
}
```

- [ ] **Step 4: Create pagination_engine.dart**

```dart
// lib/features/reader/data/pagination_engine.dart
import 'package:flutter/material.dart';
import 'package:readlive/features/reader/domain/page_content.dart';

class PaginationEngine {
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double screenWidth;
  final double screenHeight;
  final EdgeInsets padding;

  PaginationEngine({
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.screenWidth,
    required this.screenHeight,
    required this.padding,
  });

  List<PageContent> paginate(String text) {
    if (text.isEmpty) {
      return [const PageContent(text: '', startIndex: 0, endIndex: 0)];
    }

    final availableWidth = screenWidth - padding.left - padding.right;
    final availableHeight = screenHeight - padding.top - padding.bottom;
    final actualLineHeight = fontSize * lineHeight;
    final linesPerPage = (availableHeight / actualLineHeight).floor();

    if (linesPerPage <= 0) {
      return [PageContent(text: text, startIndex: 0, endIndex: text.length)];
    }

    // Approximate characters per line (Chinese characters are ~fontSize wide)
    final charsPerLine = (availableWidth / fontSize).floor();
    if (charsPerLine <= 0) {
      return [PageContent(text: text, startIndex: 0, endIndex: text.length)];
    }

    final paragraphs = text.split('\n');
    final pages = <PageContent>[];
    var currentText = StringBuffer();
    var currentLines = 0;
    var startIndex = 0;
    var charOffset = 0;

    for (var i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i];
      final paraLines = (para.length / charsPerLine).ceil().clamp(1, 999);

      if (currentLines + paraLines > linesPerPage && currentText.isNotEmpty) {
        pages.add(PageContent(
          text: currentText.toString().trim(),
          startIndex: startIndex,
          endIndex: charOffset,
        ));
        currentText = StringBuffer();
        currentLines = 0;
        startIndex = charOffset;
      }

      currentText.writeln(para);
      currentLines += paraLines;
      // Add paragraph spacing as ~1 line
      if (i < paragraphs.length - 1) {
        currentLines += 1;
      }
      charOffset += para.length + 1; // +1 for newline
    }

    if (currentText.isNotEmpty) {
      pages.add(PageContent(
        text: currentText.toString().trim(),
        startIndex: startIndex,
        endIndex: charOffset,
      ));
    }

    return pages.isEmpty
        ? [const PageContent(text: '', startIndex: 0, endIndex: 0)]
        : pages;
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
cd D:/ReadLive
flutter test test/features/reader/data/pagination_engine_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/reader/data/pagination_engine.dart lib/features/reader/domain/page_content.dart test/features/reader/data/pagination_engine_test.dart
git commit -m "feat: text pagination engine for reader"
```

---

### Task 11: Reader — State Management

**Files:**
- Create: `lib/features/reader/presentation/reader_provider.dart`

- [ ] **Step 1: Create reader_provider.dart**

```dart
// lib/features/reader/presentation/reader_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/reader/data/pagination_engine.dart';
import 'package:readlive/features/reader/domain/chapter_entity.dart';
import 'package:readlive/features/reader/domain/page_content.dart';

// Current book
final currentBookProvider = FutureProvider.family<BookEntity?, String>((ref, bookId) {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getBookById(bookId);
});

// Chapters for a book
final chaptersProvider = FutureProvider.family<List<ChapterEntity>, String>((ref, bookId) async {
  final db = ref.watch(databaseProvider);
  final data = await db.getChaptersByBook(bookId);
  return data.map((d) => ChapterEntity(
    id: d.id,
    bookId: d.bookId,
    title: d.title,
    url: d.url,
    content: d.content,
    index: d.chapterIndex,
    isCached: d.isCached,
  )).toList();
});

// Reader state
class ReaderState {
  final int currentChapterIndex;
  final int currentPageIndex;
  final bool isToolbarVisible;
  final bool isLocked;

  const ReaderState({
    this.currentChapterIndex = 0,
    this.currentPageIndex = 0,
    this.isToolbarVisible = false,
    this.isLocked = false,
  });

  ReaderState copyWith({
    int? currentChapterIndex,
    int? currentPageIndex,
    bool? isToolbarVisible,
    bool? isLocked,
  }) {
    return ReaderState(
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isToolbarVisible: isToolbarVisible ?? this.isToolbarVisible,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class ReaderNotifier extends StateNotifier<ReaderState> {
  final BookRepository _repo;
  final String _bookId;

  ReaderNotifier(this._repo, this._bookId) : super(const ReaderState());

  void toggleToolbar() {
    state = state.copyWith(isToolbarVisible: !state.isToolbarVisible);
  }

  void hideToolbar() {
    state = state.copyWith(isToolbarVisible: false);
  }

  void toggleLock() {
    state = state.copyWith(isLocked: !state.isLocked);
  }

  void setChapter(int index) {
    state = state.copyWith(
      currentChapterIndex: index,
      currentPageIndex: 0,
      isToolbarVisible: false,
    );
  }

  void nextPage(int totalPages) {
    if (state.currentPageIndex < totalPages - 1) {
      state = state.copyWith(
        currentPageIndex: state.currentPageIndex + 1,
        isToolbarVisible: false,
      );
    }
  }

  void previousPage() {
    if (state.currentPageIndex > 0) {
      state = state.copyWith(
        currentPageIndex: state.currentPageIndex - 1,
        isToolbarVisible: false,
      );
    }
  }

  void setPage(int index) {
    state = state.copyWith(currentPageIndex: index);
  }

  Future<void> saveProgress(int chapterIndex, int pageIndex, int totalPages) async {
    if (totalPages <= 0) return;
    final chapterProgress = pageIndex / totalPages;
    // Simplified progress: based on chapter index + page offset
    // Will be refined in Phase 3
    await _repo.updateProgress(_bookId, chapterProgress.clamp(0.0, 1.0));
  }
}

final readerNotifierProvider = StateNotifierProvider.family<ReaderNotifier, ReaderState, String>((ref, bookId) {
  final repo = ref.watch(bookRepositoryProvider);
  return ReaderNotifier(repo, bookId);
});

// Paginated pages for a chapter — use this in build() via ref.watch
final chapterPagesProvider = FutureProvider.family<List<PageContent>, ({String bookId, int chapterIndex, double screenWidth, double screenHeight})>((ref, params) async {
  final chapters = await ref.watch(chaptersProvider(params.bookId).future);
  if (chapters.isEmpty || params.chapterIndex >= chapters.length) {
    return <PageContent>[];
  }
  final content = chapters[params.chapterIndex].content ?? '';
  final engine = PaginationEngine(
    fontSize: 18,
    lineHeight: 1.8,
    paragraphSpacing: 16,
    screenWidth: params.screenWidth,
    screenHeight: params.screenHeight,
    padding: const EdgeInsets.all(16),
  );
  return engine.paginate(content);
});
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/features/reader/presentation/reader_provider.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reader/presentation/reader_provider.dart
git commit -m "feat: reader state management with chapter navigation and pagination"
```

---

### Task 12: Reader — UI Page

**Files:**
- Modify: `lib/features/reader/presentation/reader_page.dart`
- Create: `lib/features/reader/presentation/widgets/text_content_view.dart`
- Create: `lib/features/reader/presentation/widgets/reader_toolbar.dart`

- [ ] **Step 1: Create text_content_view.dart**

```dart
// lib/features/reader/presentation/widgets/text_content_view.dart
import 'package:flutter/material.dart';

class TextContentView extends StatelessWidget {
  final String text;
  final double fontSize;
  final double lineHeight;
  final Color textColor;
  final Color backgroundColor;

  const TextContentView({
    super.key,
    required this.text,
    this.fontSize = 18,
    this.lineHeight = 1.8,
    this.textColor = const Color(0xFF333333),
    this.backgroundColor = const Color(0xFFF5F0E6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: lineHeight,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create reader_toolbar.dart**

```dart
// lib/features/reader/presentation/widgets/reader_toolbar.dart
import 'package:flutter/material.dart';

class ReaderToolbar extends StatelessWidget {
  final String bookTitle;
  final int currentChapter;
  final int totalChapters;
  final bool isLocked;
  final VoidCallback onBack;
  final VoidCallback onToggleLock;
  final VoidCallback onShowChapters;
  final VoidCallback onShowSettings;
  final VoidCallback onToggleNightMode;
  final ValueChanged<int> onChapterChange;

  const ReaderToolbar({
    super.key,
    required this.bookTitle,
    required this.currentChapter,
    required this.totalChapters,
    required this.isLocked,
    required this.onBack,
    required this.onToggleLock,
    required this.onShowChapters,
    required this.onShowSettings,
    required this.onToggleNightMode,
    required this.onChapterChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top toolbar
        Container(
          color: Colors.black54,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 8,
            right: 8,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  bookTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  color: Colors.white,
                ),
                onPressed: onToggleLock,
              ),
            ],
          ),
        ),
        const Spacer(),
        // Bottom toolbar
        Container(
          color: Colors.black54,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '第${currentChapter + 1}章',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentChapter.toDouble(),
                      min: 0,
                      max: (totalChapters - 1).toDouble().clamp(0, double.infinity),
                      onChanged: (v) => onChapterChange(v.toInt()),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                    ),
                  ),
                  Text(
                    '第$totalChapters章',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.list, color: Colors.white),
                    onPressed: onShowChapters,
                    tooltip: '目录',
                  ),
                  IconButton(
                    icon: const Icon(Icons.nightlight_round, color: Colors.white),
                    onPressed: onToggleNightMode,
                    tooltip: '夜间模式',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: onShowSettings,
                    tooltip: '设置',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Update reader_page.dart with full implementation**

```dart
// lib/features/reader/presentation/reader_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/reader/presentation/reader_provider.dart';
import 'package:readlive/features/reader/presentation/widgets/text_content_view.dart';
import 'package:readlive/features/reader/presentation/widgets/reader_toolbar.dart';

class ReaderPage extends ConsumerStatefulWidget {
  final String bookId;
  const ReaderPage({super.key, required this.bookId});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(currentBookProvider(widget.bookId));
    final chaptersAsync = ref.watch(chaptersProvider(widget.bookId));
    final readerState = ref.watch(readerNotifierProvider(widget.bookId));
    final notifier = ref.read(readerNotifierProvider(widget.bookId).notifier);

    return Scaffold(
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('书籍不存在'));
          }

          return chaptersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载章节失败: $e')),
            data: (chapters) {
              if (chapters.isEmpty) {
                return const Center(child: Text('暂无章节内容'));
              }

              final chapterIndex = readerState.currentChapterIndex.clamp(
                0, chapters.length - 1);
              final content = chapters[chapterIndex].content ?? '';
              final screenSize = MediaQuery.of(context).size;

              final pagesAsync = ref.watch(chapterPagesProvider((
                bookId: widget.bookId,
                chapterIndex: chapterIndex,
                screenWidth: screenSize.width,
                screenHeight: screenSize.height,
              )));

              return pagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('分页失败: $e')),
                data: (pages) {
                  if (pages.isEmpty) {
                    return const Center(child: Text('章节内容为空'));
                  }

                  final pageIndex = readerState.currentPageIndex.clamp(
                    0, pages.length - 1);

                  return GestureDetector(
                onTapUp: (details) => _handleTap(details, screenSize, notifier, pages.length),
                onDoubleTap: () {
                  if (readerState.isLocked) {
                    notifier.toggleLock();
                  }
                },
                child: Stack(
                  children: [
                    // Content
                    TextContentView(
                      text: pages[pageIndex].text,
                      fontSize: 18,
                      lineHeight: 1.8,
                    ),
                    // Toolbar overlay
                    if (readerState.isToolbarVisible)
                      ReaderToolbar(
                        bookTitle: book.title,
                        currentChapter: chapterIndex,
                        totalChapters: chapters.length,
                        isLocked: readerState.isLocked,
                        onBack: () => context.pop(),
                        onToggleLock: notifier.toggleLock,
                        onShowChapters: () => _showChapterDrawer(chapters),
                        onShowSettings: () {},
                        onToggleNightMode: () {},
                        onChapterChange: (index) {
                          notifier.setChapter(index);
                        },
                      ),
                    // Lock indicator
                    if (readerState.isLocked)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('已锁定', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(TapUpDetails details, Size screenSize, ReaderNotifier notifier, int totalPages) {
    final dx = details.globalPosition.dx;
    final width = screenSize.width;

    if (ref.read(readerNotifierProvider(widget.bookId)).isLocked) {
      return; // Ignore taps when locked
    }

    if (dx < width * 0.3) {
      // Left area: previous page
      notifier.previousPage();
    } else if (dx > width * 0.7) {
      // Right area: next page
      notifier.nextPage(totalPages);
    } else {
      // Center area: toggle toolbar
      notifier.toggleToolbar();
    }
  }

  void _showChapterDrawer(List chapters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text('目录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: chapters.length,
                itemBuilder: (ctx, index) => ListTile(
                  title: Text(chapters[index].title),
                  onTap: () {
                    ref.read(readerNotifierProvider(widget.bookId).notifier)
                        .setChapter(index);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify app builds**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reader/
git commit -m "feat: reader page with tap zones, toolbar, chapter drawer, lock mechanism"
```

---

### Task 13: Settings — Theme Provider

**Files:**
- Create: `lib/features/settings/data/settings_repository.dart`
- Create: `lib/features/settings/presentation/settings_provider.dart`

- [ ] **Step 1: Create settings_repository.dart**

```dart
// lib/features/settings/data/settings_repository.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _themeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';
  static const _lineHeightKey = 'line_height';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<String> getThemeMode() async {
    final prefs = await _prefs();
    return prefs.getString(_themeKey) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _prefs();
    await prefs.setString(_themeKey, mode);
  }

  Future<double> getFontSize() async {
    final prefs = await _prefs();
    return prefs.getDouble(_fontSizeKey) ?? 18.0;
  }

  Future<void> setFontSize(double size) async {
    final prefs = await _prefs();
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<double> getLineHeight() async {
    final prefs = await _prefs();
    return prefs.getDouble(_lineHeightKey) ?? 1.8;
  }

  Future<void> setLineHeight(double height) async {
    final prefs = await _prefs();
    await prefs.setDouble(_lineHeightKey, height);
  }
}
```

- [ ] **Step 2: Create settings_provider.dart**

```dart
// lib/features/settings/presentation/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/features/settings/data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return ThemeModeNotifier(repo);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _repo;

  ThemeModeNotifier(this._repo) : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final mode = await _repo.getThemeMode();
    state = _parseThemeMode(mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _repo.setThemeMode(_themeModeToString(mode));
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system: return 'system';
    }
  }
}
```

- [ ] **Step 3: Update app.dart to use theme provider**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/settings_provider.dart';

class ReadLiveApp extends ConsumerWidget {
  const ReadLiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ReadLive',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
```

- [ ] **Step 4: Verify app builds**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/ lib/app.dart
git commit -m "feat: settings repository and theme mode provider with persistence"
```

---

### Task 14: Settings Page

**Files:**
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Update settings_page.dart**

```dart
// lib/features/settings/presentation/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader(title: '外观'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('主题模式'),
            subtitle: Text(_themeModeLabel(themeMode)),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),
          const Divider(),
          const _SectionHeader(title: '阅读'),
          ListTile(
            leading: const Icon(Icons.font_download),
            title: const Text('阅读设置'),
            subtitle: const Text('字号、行间距、翻页效果'),
            onTap: () {
              // Phase 3: reading settings
            },
          ),
          const Divider(),
          const _SectionHeader(title: '其他'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('ReadLive v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ReadLive',
                applicationVersion: '1.0.0',
                children: [
                  const Text('一款纯本地优先的小说阅读器\n无广告、无付费、无数据上传'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return '浅色模式';
      case ThemeMode.dark: return '深色模式';
      case ThemeMode.system: return '跟随系统';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setThemeMode(v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色模式'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setThemeMode(v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色模式'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setThemeMode(v!);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify app builds**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/settings_page.dart
git commit -m "feat: settings page with theme mode selection"
```

---

### Task 15: Profile Page

**Files:**
- Modify: `lib/features/profile/presentation/profile_page.dart`

- [ ] **Step 1: Update profile_page.dart**

```dart
// lib/features/profile/presentation/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksStreamProvider);
    final bookCount = booksAsync.whenData((books) => books.length);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          // Stats card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    icon: Icons.book,
                    label: '书籍',
                    value: '${bookCount.value ?? 0}',
                  ),
                  _StatItem(
                    icon: Icons.access_time,
                    label: '阅读时长',
                    value: '0分钟',
                  ),
                  _StatItem(
                    icon: Icons.trending_up,
                    label: '今日',
                    value: '0字',
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Menu items
          _MenuTile(
            icon: Icons.import_export,
            title: '本地文件导入',
            onTap: () {
              // Handled via bookshelf + button
            },
          ),
          _MenuTile(
            icon: Icons.cloud_outlined,
            title: '书源管理',
            subtitle: '管理网络书源规则',
            onTap: () {
              // Phase 2: book source management
            },
          ),
          _MenuTile(
            icon: Icons.backup_outlined,
            title: '本地备份/恢复',
            onTap: () {
              // Phase 4: backup
            },
          ),

          const Divider(),

          _MenuTile(
            icon: Icons.settings_outlined,
            title: '设置',
            onTap: () => context.push('/settings'),
          ),
          _MenuTile(
            icon: Icons.help_outline,
            title: '帮助与关于',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ReadLive',
                applicationVersion: '1.0.0',
                children: [
                  const Text('一款纯本地优先的小说阅读器\n无广告、无付费、无数据上传'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: Verify app builds**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/profile_page.dart
git commit -m "feat: profile page with stats, menu items, navigation to settings"
```

---

### Task 16: Integration Test — End-to-End Flow

**Files:**
- Test: `test/integration/app_flow_test.dart`

- [ ] **Step 1: Write integration test**

```dart
// test/integration/app_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/app.dart';

void main() {
  testWidgets('App launches and shows bookshelf', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ReadLiveApp()),
    );
    await tester.pumpAndSettle();

    // Should show bookshelf with novel/manga tabs
    expect(find.text('小说'), findsOneWidget);
    expect(find.text('漫画'), findsOneWidget);

    // Should show bottom navigation
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('Navigate to profile page', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ReadLiveApp()),
    );
    await tester.pumpAndSettle();

    // Tap on 我的 tab
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    // Should show profile page
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('书源管理'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run integration test**

```bash
cd D:/ReadLive
flutter test test/integration/app_flow_test.dart
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/integration/
git commit -m "test: integration tests for app launch and navigation flow"
```

---

### Task 17: Final Verification

- [ ] **Step 1: Run all tests**

```bash
cd D:/ReadLive
flutter test
```

Expected: All tests pass.

- [ ] **Step 2: Run analysis**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors, no warnings (or only info-level).

- [ ] **Step 3: Build for desktop (Windows) to verify**

```bash
cd D:/ReadLive
flutter build windows --debug
```

Expected: Build succeeds.

- [ ] **Step 4: Run on desktop**

```bash
cd D:/ReadLive
flutter run -d windows
```

Expected: App launches, shows bookshelf, can navigate to profile/settings.

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "chore: Phase 1 complete — scaffold, bookshelf, reader, settings"
```
