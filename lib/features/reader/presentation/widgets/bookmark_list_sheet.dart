import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/reader/domain/chapter_entity.dart';
import 'package:readlive/features/reader/presentation/reader_provider.dart';

class BookmarkListSheet extends ConsumerWidget {
  final String bookId;
  final List<ChapterEntity> chapters;
  final Function(int chapterIndex, int position) onJumpToBookmark;

  const BookmarkListSheet({
    super.key,
    required this.bookId,
    required this.chapters,
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
            child: Text('书签与笔记', style: theme.textTheme.titleMedium),
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
                        final chapterIndex = _resolveChapterIndex(bm.chapterId);
                        onJumpToBookmark(chapterIndex, bm.position);
                        Navigator.pop(context);
                      },
                      onDelete: () {
                        ref.read(bookmarkRepositoryProvider).deleteBookmark(bm.id);
                        ref.invalidate(bookmarksProvider(bookId));
                      },
                      onEditNote: () => _showNoteDialog(
                        context, ref, bm,
                      ),
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

  int _resolveChapterIndex(String chapterId) {
    for (var i = 0; i < chapters.length; i++) {
      if (chapters[i].id == chapterId) return i;
    }
    return 0;
  }

  Future<void> _showNoteDialog(
    BuildContext context,
    WidgetRef ref,
    BookmarksTableData bookmark,
  ) async {
    final controller = TextEditingController(text: bookmark.note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(bookmark.note != null ? '编辑笔记' : '添加笔记'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入笔记内容...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) {
      final repo = ref.read(bookmarkRepositoryProvider);
      await repo.updateBookmarkNote(bookId, bookmark.id, result);
      ref.invalidate(bookmarksProvider(bookId));
    }
  }
}

class _BookmarkTile extends StatelessWidget {
  final BookmarksTableData bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEditNote;

  const _BookmarkTile({
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
    required this.onEditNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeIcon = bookmark.type == 'highlight'
        ? Icons.highlight
        : bookmark.type == 'note'
            ? Icons.note
            : Icons.bookmark;
    final hasNote = bookmark.note != null && bookmark.note!.isNotEmpty;

    return ListTile(
      leading: Icon(typeIcon, color: theme.colorScheme.primary),
      title: Text(
        bookmark.contentPreview ?? '书签',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: hasNote
          ? Text(bookmark.note!, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              hasNote ? Icons.edit_note : Icons.note_add,
              size: 20,
            ),
            tooltip: hasNote ? '编辑笔记' : '添加笔记',
            onPressed: onEditNote,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
