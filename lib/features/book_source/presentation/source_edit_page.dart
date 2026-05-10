import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/book_source/domain/book_source_entity.dart';
import 'package:readlive/features/book_source/domain/source_rule.dart';
import 'package:readlive/features/book_source/presentation/book_source_provider.dart';

class SourceEditPage extends ConsumerStatefulWidget {
  final String sourceId;

  const SourceEditPage({super.key, required this.sourceId});

  @override
  ConsumerState<SourceEditPage> createState() => _SourceEditPageState();
}

class _SourceEditPageState extends ConsumerState<SourceEditPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Basic info
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  String _contentType = 'novel';
  int _weight = 100;
  final _groupNameController = TextEditingController();

  // Search rule
  final _searchUrlController = TextEditingController();
  final _searchListController = TextEditingController();
  final _searchBookNameController = TextEditingController();
  final _searchAuthorController = TextEditingController();
  final _searchBookUrlController = TextEditingController();

  // TOC rule
  final _tocListController = TextEditingController();
  final _tocNameController = TextEditingController(text: '@text');
  final _tocUrlController = TextEditingController(text: '@href');

  // Content rule
  final _contentSelectorController = TextEditingController();
  final _contentNextPageController = TextEditingController();
  final _contentImagesController = TextEditingController();
  String _encoding = 'utf-8';

  // JSON mode
  final _jsonController = TextEditingController();

  bool _isLoading = true;
  bool _isFormMode = true;
  BookSourceEntity? _source;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _isFormMode = _tabController.index == 0);
    });
    _loadSource();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _hostController.dispose();
    _groupNameController.dispose();
    _searchUrlController.dispose();
    _searchListController.dispose();
    _searchBookNameController.dispose();
    _searchAuthorController.dispose();
    _searchBookUrlController.dispose();
    _tocListController.dispose();
    _tocNameController.dispose();
    _tocUrlController.dispose();
    _contentSelectorController.dispose();
    _contentNextPageController.dispose();
    _contentImagesController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _loadSource() async {
    final repo = ref.read(bookSourceRepositoryProvider);
    final source = await repo.getSourceById(widget.sourceId);
    if (source == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('书源不存在')),
        );
        context.pop();
      }
      return;
    }

    final rule = source.parseRule();
    _source = source;

    _nameController.text = source.name;
    _hostController.text = source.host;
    _contentType = source.contentType;
    _weight = source.weight;
    _groupNameController.text = source.groupName ?? '';

    if (rule.search != null) {
      _searchUrlController.text = rule.search!.url;
      _searchListController.text = rule.search!.list;
      _searchBookNameController.text = rule.search!.bookName ?? '';
      _searchAuthorController.text = rule.search!.author ?? '';
      _searchBookUrlController.text = rule.search!.bookUrl ?? '';
    }

    if (rule.toc != null) {
      _tocListController.text = rule.toc!.list;
      _tocNameController.text = rule.toc!.name;
      _tocUrlController.text = rule.toc!.url;
    }

    if (rule.content != null) {
      _contentSelectorController.text = rule.content!.content;
      _contentNextPageController.text = rule.content!.nextPage ?? '';
      _contentImagesController.text = rule.content!.images ?? '';
      _encoding = rule.content!.encoding;
    }

    _jsonController.text = const JsonEncoder.withIndent('  ')
        .convert(source.parseRule().toJson());

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑书源')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑书源'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '表单模式'),
            Tab(text: 'JSON模式'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormMode(),
          _buildJsonMode(),
        ],
      ),
    );
  }

  Widget _buildFormMode() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Basic info
        _SectionHeader(title: '基本信息'),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '源名称',
            hintText: '例如：笔趣阁',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hostController,
          decoration: const InputDecoration(
            labelText: '域名',
            hintText: 'https://example.com',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _contentType,
                decoration: const InputDecoration(labelText: '内容类型'),
                items: const [
                  DropdownMenuItem(value: 'novel', child: Text('小说')),
                  DropdownMenuItem(value: 'manga', child: Text('漫画')),
                ],
                onChanged: (v) => setState(() => _contentType = v ?? 'novel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '优先级',
                  hintText: '100',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: '$_weight'),
                onChanged: (v) => _weight = int.tryParse(v) ?? 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(
            labelText: '分组（可选）',
            hintText: '例如：备用',
          ),
        ),

        const Divider(height: 32),

        // Search rule
        _SectionHeader(title: '搜索规则'),
        _HelpText(text: 'URL 中用 {{key}} 表示搜索关键词，{{page}} 表示页码'),
        TextField(
          controller: _searchUrlController,
          decoration: const InputDecoration(
            labelText: '搜索 URL',
            hintText: 'https://example.com/search?q={{key}}',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchListController,
          decoration: const InputDecoration(
            labelText: '列表选择器',
            hintText: '.book-item',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchBookNameController,
          decoration: const InputDecoration(
            labelText: '书名选择器',
            hintText: '.book-name@text',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchAuthorController,
          decoration: const InputDecoration(
            labelText: '作者选择器',
            hintText: '.book-author@text',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchBookUrlController,
          decoration: const InputDecoration(
            labelText: '链接选择器',
            hintText: '.book-name@href',
          ),
        ),

        const Divider(height: 32),

        // TOC rule
        _SectionHeader(title: '目录规则'),
        _HelpText(text: '选择器格式：CSS选择器@属性|过滤器'),
        TextField(
          controller: _tocListController,
          decoration: const InputDecoration(
            labelText: '章节列表选择器',
            hintText: '.chapter-list a',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tocNameController,
                decoration: const InputDecoration(
                  labelText: '章节名',
                  hintText: '@text',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _tocUrlController,
                decoration: const InputDecoration(
                  labelText: '章节链接',
                  hintText: '@href',
                ),
              ),
            ),
          ],
        ),

        const Divider(height: 32),

        // Content rule
        _SectionHeader(title: '正文规则'),
        TextField(
          controller: _contentSelectorController,
          decoration: const InputDecoration(
            labelText: '内容选择器',
            hintText: '.chapter-content',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentNextPageController,
          decoration: const InputDecoration(
            labelText: '下一页选择器（可选）',
            hintText: '.next-page@href',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _encoding,
          decoration: const InputDecoration(labelText: '编码'),
          items: const [
            DropdownMenuItem(value: 'utf-8', child: Text('UTF-8')),
            DropdownMenuItem(value: 'gbk', child: Text('GBK')),
            DropdownMenuItem(value: 'gb2312', child: Text('GB2312')),
          ],
          onChanged: (v) => setState(() => _encoding = v ?? 'utf-8'),
        ),

        if (_contentType == 'manga') ...[
          const Divider(height: 32),
          _SectionHeader(title: '漫画图片规则'),
          _HelpText(text: 'CSS 选择器，匹配章节页面中的图片元素'),
          TextField(
            controller: _contentImagesController,
            decoration: const InputDecoration(
              labelText: '图片列表选择器',
              hintText: '.chapter-content img',
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildJsonMode() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _jsonController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '粘贴书源 JSON...',
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _formatJson,
              child: const Text('格式化 JSON'),
            ),
          ),
        ],
      ),
    );
  }

  void _formatJson() {
    try {
      final parsed = jsonDecode(_jsonController.text);
      _jsonController.text =
          const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON 格式错误: $e')),
      );
    }
  }

  Future<void> _save() async {
    try {
      SourceRule rule;

      if (_isFormMode) {
        // Build rule from form fields
        rule = SourceRule(
          name: _nameController.text.trim(),
          host: _hostController.text.trim(),
          contentType: _contentType,
          weight: _weight,
          search: _searchUrlController.text.isNotEmpty
              ? SearchRule(
                  url: _searchUrlController.text.trim(),
                  list: _searchListController.text.trim(),
                  bookName: _searchBookNameController.text.isNotEmpty
                      ? _searchBookNameController.text.trim()
                      : null,
                  author: _searchAuthorController.text.isNotEmpty
                      ? _searchAuthorController.text.trim()
                      : null,
                  bookUrl: _searchBookUrlController.text.isNotEmpty
                      ? _searchBookUrlController.text.trim()
                      : null,
                )
              : null,
          toc: _tocListController.text.isNotEmpty
              ? TocRule(
                  list: _tocListController.text.trim(),
                  name: _tocNameController.text.trim(),
                  url: _tocUrlController.text.trim(),
                )
              : null,
          content: _contentSelectorController.text.isNotEmpty
              ? ContentRule(
                  content: _contentSelectorController.text.trim(),
                  nextPage: _contentNextPageController.text.isNotEmpty
                      ? _contentNextPageController.text.trim()
                      : null,
                  encoding: _encoding,
                  images: _contentImagesController.text.isNotEmpty
                      ? _contentImagesController.text.trim()
                      : null,
                )
              : null,
        );
      } else {
        // Parse JSON
        final json = jsonDecode(_jsonController.text);
        if (json is! Map<String, dynamic>) {
          throw Exception('JSON 必须是对象');
        }
        rule = SourceRule.fromJson(json);
      }

      // Validate
      if (rule.name.trim().isEmpty) {
        throw Exception('源名称不能为空');
      }
      if (rule.host.trim().isEmpty) {
        throw Exception('域名不能为空');
      }

      // Update in database
      final repo = ref.read(bookSourceRepositoryProvider);
      final source = _source!;

      final updated = BookSourceEntity(
        id: source.id,
        name: rule.name.trim(),
        host: rule.host.trim(),
        contentType: rule.contentType,
        enabled: source.enabled,
        weight: rule.weight,
        ruleJson: rule.toJsonString(),
        status: source.status,
        lastTestedAt: source.lastTestedAt,
        groupName: _groupNameController.text.trim().isNotEmpty
            ? _groupNameController.text.trim()
            : null,
        createdAt: source.createdAt,
      );

      await repo.updateSource(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}

class _HelpText extends StatelessWidget {
  final String text;
  const _HelpText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey)),
    );
  }
}
