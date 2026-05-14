import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/core/widgets/app_drawer.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/bookshelf/presentation/widgets/book_card.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';
import 'package:readlive/features/reader/data/txt_parser.dart';
import 'package:readlive/features/reader/data/epub_parser.dart';
import 'package:readlive/features/reader/data/cbz_parser.dart';
import 'package:readlive/features/reader/data/pdf_parser.dart';

class BookshelfPage extends ConsumerStatefulWidget {
  final String contentType;
  const BookshelfPage({super.key, required this.contentType});

  @override
  ConsumerState<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends ConsumerState<BookshelfPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _selectionMode = false;
  final Set<String> _selectedBooks = {};
  String? _activeGroupId;
  bool _listView = false;
  String _sortMode = 'name'; // 'name', 'recent', 'unread'
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.contentType == 'manga' ? 1 : 0;
  }

  @override
  void didUpdateWidget(BookshelfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tabController.index = widget.contentType == 'manga' ? 1 : 0;
    if (oldWidget.contentType != widget.contentType) {
      _exitSelectionMode();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String bookId) {
    setState(() {
      _selectionMode = true;
      _selectedBooks.clear();
      _selectedBooks.add(bookId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedBooks.clear();
    });
  }

  void _toggleSelection(String bookId) {
    setState(() {
      if (_selectedBooks.contains(bookId)) {
        _selectedBooks.remove(bookId);
        if (_selectedBooks.isEmpty) _selectionMode = false;
      } else {
        _selectedBooks.add(bookId);
      }
    });
  }

  void _selectAll(List<BookEntity> books) {
    setState(() {
      _selectedBooks.clear();
      _selectedBooks.addAll(books.map((b) => b.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(bookGroupsProvider);
    final statsAsync = ref.watch(readingStatsProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation bar
            _buildTopBar(theme, statsAsync),
            // Group filter chips
            groupsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (groups) {
                if (groups.isEmpty && !_selectionMode) {
                  return const SizedBox.shrink();
                }
                return _buildGroupFilterChips(groups);
              },
            ),
            // Book list
            Expanded(
              child: _BookList(
                contentType: widget.contentType,
                groupId: _activeGroupId,
                sortMode: _sortMode,
                selectionMode: _selectionMode,
                selectedBooks: _selectedBooks,
                listView: _listView,
                onTap: (book) {
                  if (_selectionMode) {
                    _toggleSelection(book.id);
                  } else {
                    final chapter = book.lastChapterIndex;
                    final query = chapter > 0 ? '?chapter=$chapter' : '';
                    context.push('/reader/${book.id}$query');
                  }
                },
                onLongPress: (bookId) {
                  if (!_selectionMode) _enterSelectionMode(bookId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, AsyncValue statsAsync) {
    if (_selectionMode) {
      return _buildSelectionBar(theme);
    }
    return Column(
      children: [
        // Main nav row
        SizedBox(
          height: 48,
          child: Stack(
            children: [
              // Center tab switch
              Center(child: _buildTabSwitch(theme)),
              // Left: hamburger menu
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.menu, size: 24),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              // Right: search + add
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, size: 22),
                      onPressed: () => context.push('/search'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 22),
                      onPressed: _importFile,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Stats + action buttons row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              // Reading time
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) {
                  if (stats.totalSeconds <= 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '阅读时长 ${stats.totalFormatted}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
              const Spacer(),
              // Action buttons: 编辑 | 筛选 | 列表
              _buildTextButton('编辑', Icons.edit_outlined, () {
                // Toggle selection mode with first book
                final books = ref.read(groupFilteredBooksProvider(
                  (contentType: widget.contentType, groupId: _activeGroupId),
                ));
                books.whenData((list) {
                  if (list.isNotEmpty) _enterSelectionMode(list.first.id);
                });
              }),
              _buildTextButton('筛选', Icons.filter_list_outlined, () {
                _showFilterSheet();
              }),
              _buildTextButton(
                _listView ? '网格' : '列表',
                _listView ? Icons.grid_view_outlined : Icons.view_list_outlined,
                () => setState(() => _listView = !_listView),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitch(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        final newIndex = _tabController.index == 0 ? 1 : 0;
        _tabController.index = newIndex;
        context.go(newIndex == 0 ? '/' : '/manga');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '书库',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: _tabController.index == 0
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: _tabController.index == 0
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '/',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            Text(
              '漫画',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: _tabController.index == 1
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: _tabController.index == 1
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextButton(String label, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(ThemeData theme) {
    final groupsAsync = ref.watch(bookGroupsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 24),
            onPressed: _exitSelectionMode,
          ),
          Expanded(
            child: Text(
              '已选 ${_selectedBooks.length} 项',
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.select_all, size: 22),
            tooltip: '全选',
            onPressed: () {
              final books = ref.read(groupFilteredBooksProvider(
                (contentType: widget.contentType, groupId: _activeGroupId),
              ));
              books.whenData((list) => _selectAll(list));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 22),
            tooltip: '批量删除',
            onPressed: _batchDelete,
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined, size: 22),
            tooltip: '移动到分组',
            onPressed: () => _showMoveToGroupDialog(groupsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilterChips(List<BookGroupsTableData> groups) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        children: [
          _buildChip('全部', _activeGroupId == null,
              () => setState(() => _activeGroupId = null)),
          _buildChip('未分组', _activeGroupId == '__ungrouped',
              () => setState(() => _activeGroupId = '__ungrouped')),
          ...groups.map((g) => _buildChip(g.name, _activeGroupId == g.id,
              () => setState(() => _activeGroupId = g.id))),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('筛选',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: Icon(Icons.sort_by_alpha,
                  color: _sortMode == 'name'
                      ? Theme.of(context).colorScheme.primary
                      : null),
              title: const Text('按书名排序'),
              trailing: _sortMode == 'name'
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                setState(() => _sortMode = 'name');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.access_time,
                  color: _sortMode == 'recent'
                      ? Theme.of(context).colorScheme.primary
                      : null),
              title: const Text('按最近阅读排序'),
              trailing: _sortMode == 'recent'
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                setState(() => _sortMode = 'recent');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle_outline,
                  color: _sortMode == 'unread'
                      ? Theme.of(context).colorScheme.primary
                      : null),
              title: const Text('只看未读完'),
              trailing: _sortMode == 'unread'
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                setState(() => _sortMode = 'unread');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'epub', 'pdf', 'cbz', 'cbr'],
        allowMultiple: true, // Enable batch import
      );
      if (result == null || result.files.isEmpty) return;

      final repo = ref.read(bookRepositoryProvider);
      var imported = 0;
      var failed = 0;

      for (final file in result.files) {
        final filePath = file.path;
        if (filePath == null) {
          failed++;
          continue;
        }

        final f = File(filePath);
        if (!await f.exists()) {
          failed++;
          continue;
        }

        try {
          if (filePath.toLowerCase().endsWith('.txt')) {
            final parser = TxtParser();
            await parser.importTxtFile(filePath, repo);
            imported++;
          } else if (filePath.toLowerCase().endsWith('.epub')) {
            final parser = EpubParser();
            await parser.importEpubFile(filePath, repo);
            imported++;
          } else if (filePath.toLowerCase().endsWith('.pdf')) {
            final parser = PdfParser();
            await parser.importPdfFile(filePath, repo);
            imported++;
          } else if (filePath.toLowerCase().endsWith('.cbz') ||
                     filePath.toLowerCase().endsWith('.cbr')) {
            final parser = CbzParser();
            await parser.importCbzFile(filePath, repo);
            imported++;
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
        }
      }

      if (mounted) {
        final msg = failed > 0
            ? '导入完成: $imported 本成功, $failed 本失败'
            : '导入完成: $imported 本书';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    } catch (e, stackTrace) {
      debugPrint('导入失败: $e\n$stackTrace');
      _showError('导入失败: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 10)),
      );
    }
  }

  void _batchDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedBooks.length} 本书吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final repo = ref.read(bookGroupRepositoryProvider);
              await repo.batchDeleteBooks(_selectedBooks.toList());
              ref.invalidate(booksStreamProvider);
              Navigator.pop(ctx);
              _exitSelectionMode();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showMoveToGroupDialog(AsyncValue<List<BookGroupsTableData>> groupsAsync) {
    groupsAsync.whenData((groups) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('移动到分组',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('取消分组'),
                onTap: () async {
                  final repo = ref.read(bookGroupRepositoryProvider);
                  await repo.moveBooksToGroup(_selectedBooks.toList(), null);
                  ref.invalidate(booksStreamProvider);
                  Navigator.pop(ctx);
                  _exitSelectionMode();
                },
              ),
              ...groups.map((g) => ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(g.name),
                    onTap: () async {
                      final repo = ref.read(bookGroupRepositoryProvider);
                      await repo.moveBooksToGroup(
                          _selectedBooks.toList(), g.id);
                      ref.invalidate(booksStreamProvider);
                      Navigator.pop(ctx);
                      _exitSelectionMode();
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    });
  }
}

class _BookList extends ConsumerWidget {
  final String contentType;
  final String? groupId;
  final String sortMode;
  final bool selectionMode;
  final Set<String> selectedBooks;
  final bool listView;
  final void Function(BookEntity book) onTap;
  final void Function(String bookId) onLongPress;

  const _BookList({
    required this.contentType,
    this.groupId,
    required this.sortMode,
    required this.selectionMode,
    required this.selectedBooks,
    required this.listView,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(groupFilteredBooksProvider(
      (contentType: contentType, groupId: groupId),
    ));

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
                    size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text('暂无书籍',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('点击右上角 + 导入书籍',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        // Apply sorting/filtering
        final sortedBooks = List<BookEntity>.from(books);
        switch (sortMode) {
          case 'name':
            sortedBooks.sort((a, b) => _naturalCompare(a.title, b.title));
          case 'recent':
            sortedBooks.sort((a, b) {
              final aTime = a.lastReadAt ?? 0;
              final bTime = b.lastReadAt ?? 0;
              return bTime.compareTo(aTime); // Descending: most recent first
            });
          case 'unread':
            sortedBooks.removeWhere((b) => b.bookProgress >= 0.99);
            sortedBooks.sort((a, b) {
              final aTime = a.lastReadAt ?? 0;
              final bTime = b.lastReadAt ?? 0;
              return bTime.compareTo(aTime);
            });
        }

        if (sortedBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text('没有未读完的书籍',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }

        if (listView) {
          return _buildListView(context, sortedBooks);
        }
        return _buildGridView(context, sortedBooks);
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<BookEntity> books) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookCard(
          book: book,
          selected: selectedBooks.contains(book.id),
          selectionMode: selectionMode,
          onTap: () => onTap(book),
          onLongPress: () => onLongPress(book.id),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, List<BookEntity> books) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: book.coverPath != null
                  ? FutureBuilder<String?>(
                      future: resolveCoverPath(book.coverPath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              File(snapshot.data!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  book.title.substring(
                                      0, book.title.length.clamp(0, 2)),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return Center(
                          child: Text(
                            book.title.substring(
                                0, book.title.length.clamp(0, 2)),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        book.title.substring(
                            0, book.title.length.clamp(0, 2)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
            ),
            title: Text(book.title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: book.author != null
                ? Text(book.author!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall)
                : null,
            trailing: Text(
              '${(book.bookProgress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            selected: selectedBooks.contains(book.id),
            onTap: () => onTap(book),
            onLongPress: () => onLongPress(book.id),
          ),
        );
      },
    );
  }
}

/// Natural sort comparison that handles Arabic and Chinese numbers.
/// "第2卷" < "第10卷", "第一卷" < "第二卷" < "第十卷" < "第十一卷"
int _naturalCompare(String a, String b) {
  // Pattern: Arabic numbers, Chinese number sequences, or other text
  final pattern = RegExp(r'(\d+)|([零一二三四五六七八九十百千万亿]+)|(\D+?)(?=\d|[零一二三四五六七八九十百千万亿]|$)');
  final aMatches = pattern.allMatches(a).toList();
  final bMatches = pattern.allMatches(b).toList();

  for (var i = 0; i < aMatches.length && i < bMatches.length; i++) {
    final aPart = aMatches[i].group(0)!;
    final bPart = bMatches[i].group(0)!;

    final aNum = _tryParseNumber(aPart);
    final bNum = _tryParseNumber(bPart);

    if (aNum != null && bNum != null) {
      // Both are numbers: compare numerically
      final cmp = aNum.compareTo(bNum);
      if (cmp != 0) return cmp;
    } else {
      // At least one is text: compare as string
      final cmp = aPart.compareTo(bPart);
      if (cmp != 0) return cmp;
    }
  }

  // Shorter string comes first
  return aMatches.length.compareTo(bMatches.length);
}

/// Try to parse a string as a number (Arabic or Chinese).
/// Returns null if not a valid number.
int? _tryParseNumber(String s) {
  // Try Arabic number
  final arabic = int.tryParse(s);
  if (arabic != null) return arabic;

  // Try Chinese number
  return _parseChineseNumber(s);
}

/// Parse Chinese number string to int.
/// Supports: 一二三...十百千万亿, e.g., 一, 十, 十一, 二十, 一百二十三
int? _parseChineseNumber(String s) {
  if (s.isEmpty) return null;

  const digits = {
    '零': 0, '一': 1, '二': 2, '三': 3, '四': 4,
    '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
  };
  const units = {
    '十': 10, '百': 100, '千': 1000, '万': 10000, '亿': 100000000,
  };

  // Single digit
  if (s.length == 1 && digits.containsKey(s)) {
    return digits[s];
  }

  // Parse compound Chinese numbers
  var result = 0;
  var current = 0;
  var hasDigit = false;

  for (final char in s.split('')) {
    if (digits.containsKey(char)) {
      current = digits[char]!;
      hasDigit = true;
    } else if (units.containsKey(char)) {
      final unit = units[char]!;
      if (current == 0 && !hasDigit) {
        // Handle cases like "十" (meaning 10, not 0*10)
        current = 1;
      }
      if (unit >= 10000) {
        // 万 and 亿 are multipliers for the accumulated result
        result = (result + current) * unit;
        current = 0;
      } else {
        result += current * unit;
        current = 0;
      }
      hasDigit = false;
    } else {
      return null; // Not a Chinese number
    }
  }

  result += current;
  return result > 0 ? result : null;
}
