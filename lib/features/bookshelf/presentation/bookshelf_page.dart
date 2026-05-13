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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              // Hamburger menu
              IconButton(
                icon: const Icon(Icons.menu, size: 24),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              // Tab switch: 书库 / 漫画
              Expanded(
                child: Center(
                  child: _buildTabSwitch(theme),
                ),
              ),
              // Search + Add
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
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('按书名排序'),
              onTap: () {
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('按最近阅读排序'),
              onTap: () {
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('只看未读完'),
              onTap: () {
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
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final filePath = file.path;
      if (filePath == null) {
        _showError('无法获取文件路径');
        return;
      }

      final f = File(filePath);
      if (!await f.exists()) {
        _showError('文件不存在: $filePath');
        return;
      }

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
      } else if (filePath.toLowerCase().endsWith('.pdf')) {
        final parser = PdfParser();
        final book = await parser.importPdfFile(filePath, repo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入: ${book.title}')),
          );
        }
      } else if (filePath.toLowerCase().endsWith('.cbz') ||
                 filePath.toLowerCase().endsWith('.cbr')) {
        final parser = CbzParser();
        final book = await parser.importCbzFile(filePath, repo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入: ${book.title}')),
          );
        }
      } else {
        _showError('不支持的文件格式');
      }
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
  final bool selectionMode;
  final Set<String> selectedBooks;
  final bool listView;
  final void Function(BookEntity book) onTap;
  final void Function(String bookId) onLongPress;

  const _BookList({
    required this.contentType,
    this.groupId,
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
        if (listView) {
          return _buildListView(context, books);
        }
        return _buildGridView(context, books);
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
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(book.coverPath!),
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
              '${(book.progress * 100).toStringAsFixed(0)}%',
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
