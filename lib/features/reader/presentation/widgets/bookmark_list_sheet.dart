import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/reader/presentation/reader_provider.dart';

class BookmarkListSheet extends ConsumerWidget {
  final String bookId;
  final Function(int chapterIndex, int position) onJumpToBookmark;

  const BookmarkListSheet({
    super.key,
    required this.bookId,
    required this.onJumpToBookmark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider(bookId));
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('书签', style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: bookmarksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (bookmarks) {
                if (bookmarks.isEmpty) {
                  return const Center(child: Text('暂无书签'));
                }
                return ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bm = bookmarks[index];
                    return _BookmarkTile(
                      bookmark: bm,
                      onTap: () {
                        onJumpToBookmark(0, bm.position);
                        Navigator.pop(context);
                      },
                      onDelete: () {
                        ref.read(bookmarkRepositoryProvider).deleteBookmark(bm.id);
                        ref.invalidate(bookmarksProvider(bookId));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final BookmarksTableData bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkTile({
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeIcon = bookmark.type == 'highlight'
        ? Icons.highlight
        : bookmark.type == 'note'
            ? Icons.note
            : Icons.bookmark;

    return ListTile(
      leading: Icon(typeIcon, color: theme.colorScheme.primary),
      title: Text(
        bookmark.contentPreview ?? '书签',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: bookmark.note != null
          ? Text(bookmark.note!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
