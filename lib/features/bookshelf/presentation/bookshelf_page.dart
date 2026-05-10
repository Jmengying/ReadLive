import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:readlive/core/database/app_database.dart';
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
  String? _activeGroupId; // null = all, '__ungrouped' = ungrouped, else groupId

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
    final groupsAsync = ref.watch(bookGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('已选 ${_selectedBooks.length} 项')
            : TabBar(
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
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (!_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push('/search'),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'groups') {
                  context.push('/groups');
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'groups', child: Text('分组管理')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _importFile,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: '全选',
              onPressed: () {
                final books = ref.read(groupFilteredBooksProvider(
                  (contentType: widget.contentType, groupId: _activeGroupId),
                ));
                books.whenData((list) => _selectAll(list));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '批量删除',
              onPressed: _batchDelete,
            ),
            IconButton(
              icon: const Icon(Icons.folder_outlined),
              tooltip: '移动到分组',
              onPressed: () => _showMoveToGroupDialog(groupsAsync),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Group filter chips
          groupsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (groups) {
              if (groups.isEmpty && !_selectionMode) return const SizedBox.shrink();
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
              onTap: (bookId) {
                if (_selectionMode) {
                  _toggleSelection(bookId);
                } else {
                  context.push('/reader/$bookId');
                }
              },
              onLongPress: (bookId) {
                if (!_selectionMode) _enterSelectionMode(bookId);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilterChips(List<BookGroupsTableData> groups) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('全部'),
              selected: _activeGroupId == null,
              onSelected: (_) => setState(() => _activeGroupId = null),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('未分组'),
              selected: _activeGroupId == '__ungrouped',
              onSelected: (_) => setState(() => _activeGroupId = '__ungrouped'),
            ),
          ),
          ...groups.map((g) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(g.name),
              selected: _activeGroupId == g.id,
              onSelected: (_) => setState(() => _activeGroupId = g.id),
            ),
          )),
        ],
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
                child: Text('移动到分组', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                  await repo.moveBooksToGroup(_selectedBooks.toList(), g.id);
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
  final void Function(String bookId) onTap;
  final void Function(String bookId) onLongPress;

  const _BookList({
    required this.contentType,
    this.groupId,
    required this.selectionMode,
    required this.selectedBooks,
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
              selected: selectedBooks.contains(book.id),
              selectionMode: selectionMode,
              onTap: () => onTap(book.id),
              onLongPress: () => onLongPress(book.id),
            );
          },
        );
      },
    );
  }
}
