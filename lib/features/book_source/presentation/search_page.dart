import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/book_source/presentation/book_source_provider.dart';
import 'package:readlive/features/book_source/domain/search_result.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索书名...',
            border: InputBorder.none,
          ),
          onSubmitted: (query) {
            ref.read(searchProvider.notifier).search(query);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ref.read(searchProvider.notifier).search(_controller.text);
            },
          ),
        ],
      ),
      body: searchState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : searchState.error != null
              ? Center(child: Text(searchState.error!))
              : searchState.results.isEmpty
                  ? const Center(child: Text('输入书名搜索'))
                  : ListView.builder(
                      itemCount: searchState.results.length,
                      itemBuilder: (context, index) {
                        final result = searchState.results[index];
                        return _SearchResultTile(
                          result: result,
                          onTap: () {
                            context.push(
                              '/book-detail?bookUrl=${Uri.encodeComponent(result.bookUrl)}'
                              '&sourceId=${result.sourceId}'
                              '&bookName=${Uri.encodeComponent(result.bookName)}',
                            );
                          },
                        );
                      },
                    ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _SearchResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            result.bookName.substring(0, result.bookName.length.clamp(0, 2)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
      title: Text(result.bookName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${result.author ?? "未知作者"} · ${result.sourceName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
