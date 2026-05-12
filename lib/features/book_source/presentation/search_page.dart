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

  void _doSearch() {
    final query = _controller.text;
    if (query.trim().isNotEmpty) {
      ref.read(searchProvider.notifier).search(query);
    }
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
          onSubmitted: (_) => _doSearch(),
        ),
        actions: [
          if (searchState.isLoading)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '取消搜索',
              onPressed: () {
                ref.read(searchProvider.notifier).cancel();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '搜索',
              onPressed: _doSearch,
            ),
        ],
      ),
      body: _buildBody(searchState),
    );
  }

  Widget _buildBody(SearchState searchState) {
    final query = searchState.query;

    // Empty query: show hint
    if (query.isEmpty) {
      return const Center(child: Text('输入书名搜索'));
    }

    final sourceStates = searchState.sourceStates;

    // No sources available yet and still loading
    if (sourceStates.isEmpty && searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // No sources available and not loading
    if (sourceStates.isEmpty && !searchState.isLoading) {
      return const Center(child: Text('没有可用的书源'));
    }

    // Grouped source list
    return Column(
      children: [
        // Status bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (searchState.isLoading) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  '搜索中 ${searchState.completedCount}/${sourceStates.length} 个源，'
                  '已找到 ${searchState.totalResultCount} 条结果',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else
                Text(
                  '共 ${searchState.totalResultCount} 条结果，'
                  '来自 ${sourceStates.where((s) => s.results.isNotEmpty).length} 个源',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Source groups
        Expanded(
          child: ListView.builder(
            itemCount: sourceStates.length,
            itemBuilder: (context, index) {
              final sourceState = sourceStates[index];
              return _SourceGroupTile(
                sourceState: sourceState,
                initiallyExpanded:
                    sourceState.isLoading || sourceState.results.isNotEmpty,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SourceGroupTile extends StatefulWidget {
  final SourceSearchState sourceState;
  final bool initiallyExpanded;

  const _SourceGroupTile({
    required this.sourceState,
    this.initiallyExpanded = true,
  });

  @override
  State<_SourceGroupTile> createState() => _SourceGroupTileState();
}

class _SourceGroupTileState extends State<_SourceGroupTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(_SourceGroupTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand when loading starts, auto-collapse when done with no results
    if (widget.sourceState.isLoading && !oldWidget.sourceState.isLoading) {
      _expanded = true;
    }
    if (!widget.sourceState.isLoading &&
        oldWidget.sourceState.isLoading &&
        widget.sourceState.results.isEmpty) {
      _expanded = false;
    }
  }

  Widget _buildStatusChip(BuildContext context, SourceSearchState state) {
    final theme = Theme.of(context);
    if (state.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (state.error != null) {
      return Icon(
        Icons.error_outline,
        size: 20,
        color: theme.colorScheme.error,
      );
    }
    return Text(
      '${state.results.length}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildContent(BuildContext context, SourceSearchState state) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('搜索中...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child: Text(
          state.error!,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }

    if (state.results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child: Text(
          '无结果',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: state.results.map((result) {
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
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.sourceState;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.sourceName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(context, state),
              ],
            ),
          ),
        ),
        if (_expanded) _buildContent(context, state),
        const Divider(height: 1),
      ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 32),
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
      title: Text(
        result.bookName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result.author ?? '未知作者',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
