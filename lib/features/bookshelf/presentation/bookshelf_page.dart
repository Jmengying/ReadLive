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
  }

  @override
  void didUpdateWidget(BookshelfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tabController.index = widget.contentType == 'manga' ? 1 : 0;
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
            onPressed: () => context.push('/search'),
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
