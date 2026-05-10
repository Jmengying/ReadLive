import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:readlive/features/book_source/presentation/book_source_provider.dart';
import 'package:readlive/features/book_source/domain/book_source_entity.dart';

class BookSourcePage extends ConsumerWidget {
  const BookSourcePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(bookSourcesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书源管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '导入书源',
            onPressed: () => _showImportDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.output),
            tooltip: '导出书源',
            onPressed: () => _exportSources(context, ref),
          ),
        ],
      ),
      body: sourcesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (sources) {
          if (sources.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_outlined,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('暂无书源'),
                  const SizedBox(height: 8),
                  const Text('点击右上角 + 导入书源'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              return _SourceTile(
                source: source,
                onToggle: (enabled) {
                  ref.read(bookSourceRepositoryProvider)
                      .toggleEnabled(source.id, enabled);
                },
                onDelete: () => _confirmDelete(context, ref, source),
              );
            },
          );
        },
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入书源'),
        content: Column(
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
                  child: Text('或', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            // Text paste area
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '粘贴书源 JSON...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            // Format example button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showFormatExample(context),
                child: const Text('查看格式示例'),
              ),
            ),
          ],
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
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromFile(
      BuildContext context, WidgetRef ref, BuildContext ctx) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final file = File(filePath);
      final json = await file.readAsString();
      if (ctx.mounted) {
        await _doImport(context, ref, ctx, json);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取文件失败: $e')),
        );
      }
    }
  }

  Future<void> _doImport(BuildContext context, WidgetRef ref,
      BuildContext ctx, String json) async {
    try {
      final repo = ref.read(bookSourceRepositoryProvider);
      final count = await repo.importFromJson(json);
      if (ctx.mounted) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入 $count 个书源')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  void _showFormatExample(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('书源 JSON 格式'),
        content: SingleChildScrollView(
          child: SelectableText(
            '''单个书源:
{
  "name": "示例书源",
  "host": "https://example.com",
  "search": {
    "url": "https://example.com/search?q={{key}}",
    "list": ".book-item",
    "bookName": ".book-name@text",
    "author": ".book-author@text",
    "bookUrl": ".book-name@href"
  },
  "bookInfo": {
    "cover": ".book-cover@src",
    "intro": ".book-intro@text"
  },
  "toc": {
    "list": ".chapter-list a",
    "name": "@text",
    "url": "@href"
  },
  "content": {
    "content": ".chapter-content@text"
  }
}

也支持数组格式 [源1, 源2, ...]''',
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSources(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(bookSourceRepositoryProvider);
      final json = await repo.exportToJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('书源 JSON 已复制到剪贴板')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, BookSourceEntity source) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除书源'),
        content: Text('确定删除书源 "${source.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(bookSourceRepositoryProvider).deleteSource(source.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final BookSourceEntity source;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _SourceTile({
    required this.source,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(source.name),
      subtitle: Text(
        source.host,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Icon(
        Icons.cloud_outlined,
        color: source.enabled
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: source.enabled,
            onChanged: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
