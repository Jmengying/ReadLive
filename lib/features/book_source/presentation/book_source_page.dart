import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:readlive/features/book_source/presentation/book_source_provider.dart';
import 'package:readlive/features/book_source/domain/book_source_entity.dart';

class BookSourcePage extends ConsumerStatefulWidget {
  const BookSourcePage({super.key});

  @override
  ConsumerState<BookSourcePage> createState() => _BookSourcePageState();
}

class _BookSourcePageState extends ConsumerState<BookSourcePage> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, novel, manga, error
  String _sortBy = 'weight'; // weight, name, lastTested
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(bookSourcesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: _selectMode
            ? Text('已选 ${_selectedIds.length} 项')
            : const Text('书源管理'),
        leading: _selectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectMode = false;
                  _selectedIds.clear();
                }),
              )
            : null,
        actions: _selectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: '全选',
                  onPressed: () => setState(() {
                    final sources = ref.read(bookSourcesStreamProvider).valueOrNull ?? [];
                    if (_selectedIds.length == sources.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(sources.map((s) => s.id));
                    }
                  }),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: '启用选中',
                  onPressed: () => _batchToggle(ref, true),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: '禁用选中',
                  onPressed: () => _batchToggle(ref, false),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除选中',
                  onPressed: () => _batchDelete(context, ref),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.speed),
                  tooltip: '一键测试全部',
                  onPressed: () => _testAllSources(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  tooltip: '去重',
                  onPressed: () => _deduplicate(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: '批量管理',
                  onPressed: () => setState(() => _selectMode = true),
                ),
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
          // Apply filters and search
          var filtered = sources.where((s) {
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              if (!s.name.toLowerCase().contains(q) &&
                  !s.host.toLowerCase().contains(q)) {
                return false;
              }
            }
            if (_filterType == 'novel' && s.contentType != 'novel') return false;
            if (_filterType == 'manga' && s.contentType != 'manga') return false;
            if (_filterType == 'error' && s.status != 'error') return false;
            return true;
          }).toList();

          // Apply sort
          filtered.sort((a, b) {
            switch (_sortBy) {
              case 'name':
                return a.name.compareTo(b.name);
              case 'lastTested':
                return (b.lastTestedAt ?? 0).compareTo(a.lastTestedAt ?? 0);
              case 'weight':
              default:
                return b.weight.compareTo(a.weight);
            }
          });

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

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '搜索源名称或域名...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              // Filter chips and sort
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: '全部',
                              selected: _filterType == 'all',
                              onSelected: () => setState(() => _filterType = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '小说',
                              selected: _filterType == 'novel',
                              onSelected: () => setState(() => _filterType = 'novel'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '漫画',
                              selected: _filterType == 'manga',
                              onSelected: () => setState(() => _filterType = 'manga'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '失效',
                              selected: _filterType == 'error',
                              onSelected: () => setState(() => _filterType = 'error'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      tooltip: '排序',
                      onSelected: (v) => setState(() => _sortBy = v),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'weight', child: Text('按优先级')),
                        const PopupMenuItem(value: 'name', child: Text('按名称')),
                        const PopupMenuItem(value: 'lastTested', child: Text('按测试时间')),
                      ],
                    ),
                  ],
                ),
              ),
              // Source count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '共 ${filtered.length} 个书源',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              // Source list
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final source = filtered[index];
                    return _SourceTile(
                      source: source,
                      selectMode: _selectMode,
                      selected: _selectedIds.contains(source.id),
                      onSelectChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedIds.add(source.id);
                          } else {
                            _selectedIds.remove(source.id);
                          }
                        });
                      },
                      onToggle: (enabled) {
                        ref.read(bookSourceRepositoryProvider)
                            .toggleEnabled(source.id, enabled);
                      },
                      onDelete: () => _confirmDelete(context, ref, source),
                      onTest: () => _testSource(context, ref, source),
                      onEdit: () => context.push(
                          '/source-edit?sourceId=${source.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _testSource(
      BuildContext context, WidgetRef ref, BookSourceEntity source) async {
    // Show testing status
    ref.read(bookSourceRepositoryProvider)
        .updateSourceStatus(source.id, 'testing');

    final tester = ref.read(sourceTesterProvider);
    final result = await tester.testSource(source);

    // Update status based on result
    ref.read(bookSourceRepositoryProvider)
        .updateSourceStatus(source.id, result.success ? 'active' : 'error');

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('测试结果: ${source.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.searchOk != null)
                _ResultRow(
                  label: '搜索',
                  ok: result.searchOk!,
                  detail: '${result.resultCount ?? 0}条结果',
                ),
              if (result.tocOk != null)
                _ResultRow(
                  label: '目录',
                  ok: result.tocOk!,
                  detail: '${result.chapterCount ?? 0}章',
                ),
              if (result.contentOk != null)
                _ResultRow(
                  label: '正文',
                  ok: result.contentOk!,
                  detail: '${result.contentLength ?? 0}字',
                ),
              const SizedBox(height: 8),
              Text('响应时间: ${result.responseTimeMs}ms',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (result.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(result.errorMessage!,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
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

  Future<void> _testAllSources(BuildContext context, WidgetRef ref) async {
    final sources = ref.read(bookSourcesStreamProvider).valueOrNull ?? [];
    if (sources.isEmpty) return;

    final enabledSources = sources.where((s) => s.enabled).toList();
    if (enabledSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有已启用的书源')),
      );
      return;
    }

    // Reset state
    _testProgressNotifier.value = 0;
    _testCancelNotifier.value = false;

    // Show progress dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('测试中...'),
        content: _TestAllProgress(total: enabledSources.length),
        actions: [
          TextButton(
            onPressed: () => _testCancelNotifier.value = true,
            child: const Text('取消'),
          ),
        ],
      ),
    );

    final tester = ref.read(sourceTesterProvider);
    final repo = ref.read(bookSourceRepositoryProvider);
    var successCount = 0;
    var failCount = 0;
    var cancelled = false;

    for (var i = 0; i < enabledSources.length; i++) {
      if (_testCancelNotifier.value) {
        cancelled = true;
        break;
      }
      final source = enabledSources[i];
      repo.updateSourceStatus(source.id, 'testing');
      final result = await tester.testSource(source);
      repo.updateSourceStatus(source.id, result.success ? 'active' : 'error');
      if (result.success) {
        successCount++;
      } else {
        failCount++;
      }
      // Update progress
      _testProgressNotifier.value = i + 1;
    }

    if (context.mounted) {
      Navigator.pop(context); // Close progress dialog
      if (cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已取消: $successCount 成功, $failCount 失败')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('测试完成: $successCount 成功, $failCount 失败')),
        );
      }
    }
  }

  static final _testProgressNotifier = ValueNotifier<int>(0);
  static final _testCancelNotifier = ValueNotifier<bool>(false);

  Future<void> _batchToggle(WidgetRef ref, bool enabled) async {
    if (_selectedIds.isEmpty) return;
    final repo = ref.read(bookSourceRepositoryProvider);
    await repo.toggleSources(_selectedIds.toList(), enabled);
    setState(() {
      _selectMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _batchDelete(BuildContext context, WidgetRef ref) async {
    if (_selectedIds.isEmpty) return;

    // Check if any built-in sources are selected
    final sources = ref.read(bookSourcesStreamProvider).valueOrNull ?? [];
    final builtInCount = sources.where((s) => _selectedIds.contains(s.id) && s.builtIn).length;
    if (builtInCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已跳过 $builtInCount 个内置书源（不可删除）')),
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 ${_selectedIds.length - builtInCount} 个书源吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(bookSourceRepositoryProvider);
      // Only delete non-built-in sources
      final idsToDelete = sources
          .where((s) => _selectedIds.contains(s.id) && !s.builtIn)
          .map((s) => s.id)
          .toList();
      await repo.deleteSources(idsToDelete);
      setState(() {
        _selectMode = false;
        _selectedIds.clear();
      });
    }
  }

  Future<void> _deduplicate(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(bookSourceRepositoryProvider);
    final removed = await repo.deduplicate();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(removed > 0
            ? '已去除 $removed 个重复书源'
            : '没有重复书源')),
      );
    }
  }

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
              // URL import section
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
                  icon: const Icon(Icons.link),
                  label: const Text('从 URL 导入'),
                  onPressed: () => _importFromUrls(context, ref, ctx, urlController.text),
                ),
              ),
              const SizedBox(height: 12),
              // JSON paste section
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
      final (count, errors) = await repo.importFromJson(json);
      if (ctx.mounted) {
        Navigator.pop(ctx);
        if (count > 0 && errors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入 $count 个书源')),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
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
  "toc": {
    "list": ".chapter-list a",
    "name": "@text",
    "url": "@href"
  },
  "content": {
    "content": ".chapter-content@text"
  }
}''',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '获取可用书源:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. GitHub 搜索 "legado bookSource"'),
              const Text('2. 搜索 "阅读APP书源" 获取合集'),
              const Text('3. 支持 Legado(阅读) 格式的 JSON'),
              const SizedBox(height: 8),
              const Text(
                '提示: 也可使用 Legado 格式导入',
                style: TextStyle(color: Colors.grey),
              ),
            ],
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
    if (source.builtIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内置书源不可删除')),
      );
      return;
    }
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
  final bool selectMode;
  final bool selected;
  final ValueChanged<bool>? onSelectChanged;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTest;
  final VoidCallback? onEdit;

  const _SourceTile({
    required this.source,
    this.selectMode = false,
    this.selected = false,
    this.onSelectChanged,
    required this.onToggle,
    required this.onDelete,
    required this.onTest,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (source.status) {
      'active' => Colors.green,
      'error' => Colors.red,
      'testing' => Colors.orange,
      _ => theme.colorScheme.outline,
    };
    final statusIcon = switch (source.status) {
      'active' => Icons.check_circle,
      'error' => Icons.error,
      'testing' => Icons.hourglass_top,
      _ => Icons.help_outline,
    };

    return ListTile(
      onTap: selectMode ? () => onSelectChanged?.call(!selected) : null,
      title: Row(
        children: [
          Expanded(child: Text(source.name)),
          if (source.builtIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '内置',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              source.host,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      leading: selectMode
          ? Checkbox(
              value: selected,
              onChanged: (v) => onSelectChanged?.call(v ?? false),
            )
          : Icon(
              Icons.cloud_outlined,
              color: source.enabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
      trailing: selectMode
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: source.enabled,
                  onChanged: onToggle,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'test':
                        onTest();
                      case 'edit':
                        onEdit?.call();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'test', child: Text('测试')),
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                    const PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                ),
              ],
            ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final bool ok;
  final String detail;

  const _ResultRow({
    required this.label,
    required this.ok,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: ok ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(detail, style: TextStyle(
            color: ok ? null : Colors.red,
          )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}

class _TestAllProgress extends StatelessWidget {
  final int total;
  const _TestAllProgress({required this.total});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _BookSourcePageState._testProgressNotifier,
      builder: (context, value, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: total > 0 ? value / total : 0),
            const SizedBox(height: 8),
            Text('$value / $total'),
          ],
        );
      },
    );
  }
}
