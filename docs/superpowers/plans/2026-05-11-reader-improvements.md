# Reader Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix scroll-mode chapter switching bug, add double-tap toolbar toggle, save/restore reading position, add URL-based book source import, and import Pixiv sources.

**Architecture:** Changes span the database layer (new columns), reader UI (gesture handling, toolbar buttons), book source import (URL fetching), and app initialization. Each task is self-contained and can be tested independently.

**Tech Stack:** Flutter, Drift (SQLite), Riverpod, Dio, GoRouter

---

## File Map

| File | Change |
|------|--------|
| `lib/core/database/tables.dart` | Add `lastChapterIndex`, `lastScrollOffset` to BooksTable |
| `lib/core/database/app_database.dart` | Bump schema version, add migration, add `updateReadingPosition` method |
| `lib/core/database/app_database.g.dart` | Regenerate (run `dart run build_runner build`) |
| `lib/features/bookshelf/domain/book_entity.dart` | Add `lastChapterIndex`, `lastScrollOffset` fields |
| `lib/features/bookshelf/data/book_repository.dart` | Add `updateReadingPosition()` method |
| `lib/features/reader/presentation/reader_provider.dart` | Add `saveReadingPosition()`, `lastScrollOffset` to ReaderState |
| `lib/features/reader/presentation/reader_page.dart` | Fix scroll gestures, add double-tap toolbar, restore position on open |
| `lib/features/reader/presentation/widgets/reader_toolbar.dart` | Add prev/next chapter buttons |
| `lib/features/book_source/presentation/book_source_page.dart` | Add URL import option in import dialog |
| `lib/features/book_source/data/book_source_repository.dart` | Add `importFromUrl()` method |
| `lib/features/bookshelf/presentation/bookshelf_page.dart` | Pass saved chapter index when opening reader |

---

### Task 1: Database Schema — Add Reading Position Columns

**Files:**
- Modify: `lib/core/database/tables.dart:3-20`
- Modify: `lib/core/database/app_database.dart:15-37`
- Regenerate: `lib/core/database/app_database.g.dart`

- [ ] **Step 1: Add columns to BooksTable**

In `lib/core/database/tables.dart`, add two new columns after `progress`:

```dart
class BooksTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get author => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get filePath => text().nullable()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get bookUrl => text().nullable()();
  TextColumn get contentType => text().withDefault(const Constant('novel'))();
  TextColumn get groupId => text().nullable().references(BookGroupsTable, #id)();
  IntColumn get lastReadAt => integer().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  IntColumn get lastChapterIndex => integer().withDefault(const Constant(0))();
  RealColumn get lastScrollOffset => real().withDefault(const Constant(0.0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 2: Update database migration**

In `lib/core/database/app_database.dart`, change `schemaVersion` from 5 to 6 and add migration:

```dart
@override
int get schemaVersion => 6;

@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(bookSourcesTable);
        }
        if (from < 3) {
          await m.createTable(bookGroupsTable);
          await m.createTable(readingSessionsTable);
          await m.addColumn(booksTable, booksTable.groupId);
        }
        if (from < 4) {
          await m.addColumn(bookmarksTable, bookmarksTable.startOffset);
          await m.addColumn(bookmarksTable, bookmarksTable.endOffset);
        }
        if (from < 5) {
          await m.addColumn(bookSourcesTable, bookSourcesTable.builtIn);
        }
        if (from < 6) {
          await m.addColumn(booksTable, booksTable.lastChapterIndex);
          await m.addColumn(booksTable, booksTable.lastScrollOffset);
        }
      },
    );
```

- [ ] **Step 3: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: `app_database.g.dart` regenerated with new columns.

- [ ] **Step 4: Commit**

```bash
git add lib/core/database/tables.dart lib/core/database/app_database.dart lib/core/database/app_database.g.dart
git commit -m "feat: add lastChapterIndex and lastScrollOffset columns to BooksTable"
```

---

### Task 2: Book Entity & Repository — Reading Position

**Files:**
- Modify: `lib/features/bookshelf/domain/book_entity.dart`
- Modify: `lib/features/bookshelf/data/book_repository.dart:62-72`

- [ ] **Step 1: Update BookEntity**

In `lib/features/bookshelf/domain/book_entity.dart`, add the two new fields:

```dart
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
  final double progress;
  final int lastChapterIndex;
  final double lastScrollOffset;
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
    this.lastChapterIndex = 0,
    this.lastScrollOffset = 0.0,
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
      lastChapterIndex: data.lastChapterIndex,
      lastScrollOffset: data.lastScrollOffset,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }
}
```

- [ ] **Step 2: Add updateReadingPosition to BookRepository**

In `lib/features/bookshelf/data/book_repository.dart`, add after `updateProgress()`:

```dart
Future<void> updateReadingPosition(
  String bookId,
  int chapterIndex,
  double scrollOffset,
) async {
  final book = await _db.getBookById(bookId);
  if (book == null) return;
  final now = DateTime.now().millisecondsSinceEpoch;
  final companion = book.toCompanion(true).copyWith(
        lastChapterIndex: Value(chapterIndex),
        lastScrollOffset: Value(scrollOffset),
        lastReadAt: Value(now),
        updatedAt: Value(now),
      );
  await _db.updateBook(companion);
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/bookshelf/domain/book_entity.dart lib/features/bookshelf/data/book_repository.dart
git commit -m "feat: add reading position tracking to BookEntity and BookRepository"
```

---

### Task 3: Reader Provider — Save Reading Position

**Files:**
- Modify: `lib/features/reader/presentation/reader_provider.dart:36-120`

- [ ] **Step 1: Add lastScrollOffset to ReaderState**

In `lib/features/reader/presentation/reader_provider.dart`, update `ReaderState`:

```dart
class ReaderState {
  final int currentChapterIndex;
  final int currentPageIndex;
  final bool isToolbarVisible;
  final bool isLocked;
  final double lastScrollOffset;

  const ReaderState({
    this.currentChapterIndex = 0,
    this.currentPageIndex = 0,
    this.isToolbarVisible = false,
    this.isLocked = false,
    this.lastScrollOffset = 0.0,
  });

  ReaderState copyWith({
    int? currentChapterIndex,
    int? currentPageIndex,
    bool? isToolbarVisible,
    bool? isLocked,
    double? lastScrollOffset,
  }) {
    return ReaderState(
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isToolbarVisible: isToolbarVisible ?? this.isToolbarVisible,
      isLocked: isLocked ?? this.isLocked,
      lastScrollOffset: lastScrollOffset ?? this.lastScrollOffset,
    );
  }
}
```

- [ ] **Step 2: Add saveReadingPosition to ReaderNotifier**

In `ReaderNotifier`, add after `saveProgress()`:

```dart
Future<void> saveReadingPosition(int chapterIndex, double scrollOffset) async {
  await _repo.updateReadingPosition(_bookId, chapterIndex, scrollOffset);
}

void setLastScrollOffset(double offset) {
  state = state.copyWith(lastScrollOffset: offset);
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/reader/presentation/reader_provider.dart
git commit -m "feat: add saveReadingPosition to ReaderNotifier"
```

---

### Task 4: Reader Page — Fix Scroll Mode Gestures

**Files:**
- Modify: `lib/features/reader/presentation/reader_page.dart`

This is the largest change. It covers: removing overscroll chapter switching, adding double-tap toolbar toggle, saving scroll position periodically, and restoring position on open.

- [ ] **Step 1: Remove overscroll chapter switching**

In `lib/features/reader/presentation/reader_page.dart`, remove the overscroll-related fields and logic.

Remove these fields from `_ReaderPageState` (lines 37-40):
```dart
int _overscrollTopCount = 0;
int _overscrollBottomCount = 0;
DateTime _lastOverscrollTop = DateTime.fromMillisecondsSinceEpoch(0);
DateTime _lastOverscrollBottom = DateTime.fromMillisecondsSinceEpoch(0);
```

Remove the overscroll counter reset block (lines 207-211):
```dart
// Reset overscroll counters when chapter changes
if (_lastScrollChapterIndex != chapterIndex) {
  _overscrollTopCount = 0;
  _overscrollBottomCount = 0;
}
```

Replace the `NotificationListener<ScrollNotification>` wrapper (lines 280-311) with just the `SingleChildScrollView` directly. The full scroll mode content section becomes:

```dart
child: SingleChildScrollView(
  controller: _scrollController,
  padding: const EdgeInsets.all(16),
  child: TextContentView(
    text: chapterContent,
    fontSize: readingSettings.fontSize,
    lineHeight: readingSettings.lineHeight,
    textColor: textColor,
    backgroundColor: bgColor,
    fontFamily: readingSettings.fontFamily,
    fontWeight: readingSettings.fontWeight,
    firstLineIndent: readingSettings.firstLineIndent,
    letterSpacing: readingSettings.letterSpacing,
    eyeProtection: readingSettings.eyeProtection,
    eyeProtectionIntensity: readingSettings.eyeProtectionIntensity,
    scrollable: false,
  ),
),
```

- [ ] **Step 2: Change scroll mode tap handler to double-tap**

Replace the `GestureDetector` for scroll mode (lines 256-268). Change from `onTapUp` to `onDoubleTap` for toolbar toggle, and remove the single-tap handler:

```dart
return GestureDetector(
  onDoubleTap: () {
    if (readerState.isLocked) {
      notifier.toggleLock();
    } else {
      notifier.toggleToolbar();
    }
  },
  child: Stack(
```

Remove the `_handleScrollTap` method entirely (lines 772-817) since it's no longer used.

- [ ] **Step 3: Add scroll position saving on dispose**

In `_saveSegmentSync()` (the dispose method), also save the scroll position. Add before the existing database insert:

```dart
// Save reading position
final readerState = ref.read(readerNotifierProvider(widget.bookId));
final bookRepo = ref.read(bookRepositoryProvider);
final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
bookRepo.updateReadingPosition(
  widget.bookId,
  readerState.currentChapterIndex,
  scrollOffset,
);
```

- [ ] **Step 4: Add periodic scroll position saving**

In `_saveSegment()` (the 30-second timer callback), also save the reading position:

```dart
// Save reading position
final readerState = ref.read(readerNotifierProvider(widget.bookId));
final bookRepo = ref.read(bookRepositoryProvider);
final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
bookRepo.updateReadingPosition(
  widget.bookId,
  readerState.currentChapterIndex,
  scrollOffset,
);
```

- [ ] **Step 5: Restore scroll position on chapter load**

In the scroll mode build method, after the `_lastScrollChapterIndex != chapterIndex` check (around line 193), restore the saved scroll offset. Modify the scroll position reset logic:

```dart
// Reset scroll position when chapter changes in scroll mode
if (isScrollMode && _lastScrollChapterIndex != chapterIndex) {
  _lastScrollChapterIndex = chapterIndex;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      // If this is the initial chapter (first load), restore saved offset
      final book = ref.read(currentBookProvider(widget.bookId)).valueOrNull;
      if (book != null && chapterIndex == book.lastChapterIndex && book.lastScrollOffset > 0) {
        _scrollController.jumpTo(book.lastScrollOffset);
      } else {
        _scrollController.jumpTo(0);
      }
    }
  });
}
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/reader/presentation/reader_page.dart
git commit -m "fix: replace overscroll chapter switching with double-tap toolbar toggle, save/restore scroll position"
```

---

### Task 5: Bookshelf — Pass Saved Chapter Index

**Files:**
- Modify: `lib/features/bookshelf/presentation/bookshelf_page.dart:175-180`

- [ ] **Step 1: Update book tap to pass saved chapter**

In `lib/features/bookshelf/presentation/bookshelf_page.dart`, the `_BookList` widget's `onTap` callback needs to pass the saved chapter index. First, we need access to the book data.

Find the `onTap` callback (line 175-180) and update it. The `_BookList` needs to provide the book entity, not just the bookId. Check how `_BookList` is implemented and update accordingly.

The simplest approach: change the `onTap` signature to also accept a `BookEntity`, then pass the chapter index in the URL:

```dart
onTap: (book) {
  if (_selectionMode) {
    _toggleSelection(book.id);
  } else {
    final chapter = book.lastChapterIndex;
    final query = chapter > 0 ? '?chapter=$chapter' : '';
    context.push('/reader/${book.id}$query');
  }
},
```

This requires updating the `_BookList` widget's `onTap` callback type from `ValueChanged<String>` to `ValueChanged<BookEntity>`. Find the `_BookList` class definition and update it.

- [ ] **Step 2: Commit**

```bash
git add lib/features/bookshelf/presentation/bookshelf_page.dart
git commit -m "feat: pass saved chapter index when opening book from bookshelf"
```

---

### Task 6: Toolbar — Add Previous/Next Chapter Buttons

**Files:**
- Modify: `lib/features/reader/presentation/widgets/reader_toolbar.dart`

- [ ] **Step 1: Add prev/next chapter callbacks**

Update `ReaderToolbar` to accept `onPreviousChapter` and `onNextChapter` callbacks:

```dart
class ReaderToolbar extends StatelessWidget {
  final String bookTitle;
  final int currentChapter;
  final int totalChapters;
  final bool isLocked;
  final VoidCallback onBack;
  final VoidCallback onToggleLock;
  final VoidCallback onShowChapters;
  final VoidCallback onShowSettings;
  final VoidCallback onShowBookmarks;
  final VoidCallback onToggleNightMode;
  final VoidCallback? onToggleTts;
  final VoidCallback? onAddBookmark;
  final ValueChanged<int> onChapterChange;
  final VoidCallback? onSwitchSource;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;

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
    required this.onShowBookmarks,
    required this.onToggleNightMode,
    this.onToggleTts,
    this.onAddBookmark,
    required this.onChapterChange,
    this.onSwitchSource,
    required this.onPreviousChapter,
    required this.onNextChapter,
  });
```

- [ ] **Step 2: Add buttons to the bottom bar**

In the bottom bar's `Row` of icon buttons (around line 105-147), add prev/next chapter buttons at the beginning of the row:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    IconButton(
      icon: Icon(
        Icons.skip_previous,
        color: currentChapter > 0 ? Colors.white : Colors.white30,
      ),
      onPressed: currentChapter > 0 ? onPreviousChapter : null,
      tooltip: '上一章',
    ),
    IconButton(
      icon: const Icon(Icons.list, color: Colors.white),
      onPressed: onShowChapters,
      tooltip: '目录',
    ),
    // ... existing buttons ...
    IconButton(
      icon: Icon(
        Icons.skip_next,
        color: currentChapter < totalChapters - 1 ? Colors.white : Colors.white30,
      ),
      onPressed: currentChapter < totalChapters - 1 ? onNextChapter : null,
      tooltip: '下一章',
    ),
  ],
),
```

- [ ] **Step 3: Wire up callbacks in reader_page.dart**

In `lib/features/reader/presentation/reader_page.dart`, all places where `ReaderToolbar` is constructed need the new callbacks. There are 3 instances (scroll mode, manga page mode, novel page mode). Add to each:

```dart
onPreviousChapter: chapterIndex > 0
    ? () => notifier.setChapter(chapterIndex - 1)
    : () {},
onNextChapter: chapterIndex < chapters.length - 1
    ? () => notifier.setChapter(chapterIndex + 1)
    : () {},
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/reader/presentation/widgets/reader_toolbar.dart lib/features/reader/presentation/reader_page.dart
git commit -m "feat: add previous/next chapter buttons to reader toolbar"
```

---

### Task 7: Book Source — URL Import

**Files:**
- Modify: `lib/features/book_source/data/book_source_repository.dart`
- Modify: `lib/features/book_source/presentation/book_source_page.dart:466-537`

- [ ] **Step 1: Add importFromUrl to BookSourceRepository**

In `lib/features/book_source/data/book_source_repository.dart`, add after `importFromJson()`:

```dart
/// Import sources from one or more URLs.
/// Returns (successCount, errorMessages).
Future<(int, List<String>)> importFromUrls(List<String> urls, {bool builtIn = false}) async {
  final httpClient = HttpClient();
  var totalCount = 0;
  final allErrors = <String>[];

  for (final url in urls) {
    try {
      final response = await httpClient.dio.get<String>(
        url.trim(),
        options: Options(responseType: ResponseType.plain),
      );
      final json = response.data ?? '';
      if (json.isEmpty) {
        allErrors.add('$url: 返回内容为空');
        continue;
      }
      final (count, errors) = await importFromJson(json, builtIn: builtIn);
      totalCount += count;
      allErrors.addAll(errors.map((e) => '$url: $e'));
    } catch (e) {
      allErrors.add('$url: 下载失败 - $e');
    }
  }

  return (totalCount, allErrors);
}
```

Add the import at the top of the file:
```dart
import 'package:dio/dio.dart';
import 'package:readlive/core/network/http_client.dart';
```

- [ ] **Step 2: Add URL import tab to import dialog**

In `lib/features/book_source/presentation/book_source_page.dart`, update `_showImportDialog` to add a URL import option. Replace the dialog content with a tabbed interface or add a URL field above the existing text field:

```dart
void _showImportDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  final urlController = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('导入书源'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File picker button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('从 JSON 文件导入'),
                onPressed: () => _importFromFile(context, ref, ctx),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('从 URL 导入', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '粘贴书源 URL，多个 URL 每行一个...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('从 URL 导入'),
                onPressed: () => _importFromUrls(context, ref, ctx, urlController.text),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('或粘贴 JSON', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '粘贴书源 JSON...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showFormatExample(context),
                child: const Text('查看格式示例'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            final json = controller.text.trim();
            if (json.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入或粘贴书源 JSON')),
              );
              return;
            }
            await _doImport(context, ref, ctx, json);
          },
          child: const Text('导入 JSON'),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Add _importFromUrls method**

In `_BookSourcePageState`, add:

```dart
Future<void> _importFromUrls(
    BuildContext context, WidgetRef ref, BuildContext ctx, String urlText) async {
  final urls = urlText.split('\n').where((u) => u.trim().isNotEmpty).toList();
  if (urls.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请输入至少一个 URL')),
    );
    return;
  }

  try {
    final repo = ref.read(bookSourceRepositoryProvider);
    final (count, errors) = await repo.importFromUrls(urls);
    if (ctx.mounted) {
      Navigator.pop(ctx);
      if (count > 0 && errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已从 URL 导入 $count 个书源')),
        );
      } else if (count > 0 && errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已导入 $count 个，${errors.length} 个失败'),
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (errors.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('导入失败'),
            content: SingleChildScrollView(
              child: Text(errors.join('\n')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  } catch (e) {
    if (ctx.mounted) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('URL 导入失败: $e')),
      );
    }
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/book_source/data/book_source_repository.dart lib/features/book_source/presentation/book_source_page.dart
git commit -m "feat: add URL-based book source import"
```

---

### Task 8: Import Pixiv Sources

**Files:**
- Modify: `lib/features/book_source/presentation/book_source_page.dart`

- [ ] **Step 1: Add Pixiv source quick-import button**

In the `_showImportDialog` method, add a pre-built Pixiv sources section at the top of the dialog. Add before the file picker button:

```dart
// Quick import: Pixiv sources
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    icon: const Icon(Icons.auto_awesome),
    label: const Text('一键导入 Pixiv 书源'),
    onPressed: () => _importPixivSources(context, ref, ctx),
  ),
),
const SizedBox(height: 12),
```

- [ ] **Step 2: Add _importPixivSources method**

```dart
Future<void> _importPixivSources(
    BuildContext context, WidgetRef ref, BuildContext ctx) async {
  const pixivUrls = [
    'https://raw.githubusercontent.com/DowneyRem/PixivSource/main/normal.json',
    'https://raw.githubusercontent.com/DowneyRem/PixivSource/main/books.json',
    'https://raw.githubusercontent.com/DowneyRem/PixivSource/main/import.json',
  ];

  try {
    final repo = ref.read(bookSourceRepositoryProvider);
    final (count, errors) = await repo.importFromUrls(pixivUrls);
    if (ctx.mounted) {
      Navigator.pop(ctx);
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入 $count 个 Pixiv 书源')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pixiv 书源导入失败: ${errors.join(", ")}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  } catch (e) {
    if (ctx.mounted) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pixiv 书源导入失败: $e')),
      );
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/book_source/presentation/book_source_page.dart
git commit -m "feat: add one-click Pixiv source import"
```

---

### Task 9: Final Integration Test

- [ ] **Step 1: Run build_runner to regenerate Drift code**

```bash
cd D:/ReadLive && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Run Flutter analyze**

```bash
cd D:/ReadLive && flutter analyze
```

Expected: No errors (warnings are OK).

- [ ] **Step 3: Manual test checklist**

1. Open a book, read in scroll mode, close it. Reopen — should resume at saved position.
2. In scroll mode, double-tap — toolbar should appear/disappear.
3. In scroll mode, single tap — nothing happens (no accidental toolbar).
4. In scroll mode, swipe up/down — normal scrolling, no chapter switching.
5. Toolbar shows prev/next chapter buttons — tap them to switch chapters.
6. Book source management > Import > "一键导入 Pixiv 书源" — sources imported.
7. Book source management > Import > paste a URL — sources imported from URL.
8. Open a book in page mode — existing behavior unchanged.

- [ ] **Step 4: Final commit if any fixes needed**

```bash
git add -A && git commit -m "fix: integration fixes from manual testing"
```
