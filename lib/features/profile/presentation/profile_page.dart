import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/reader/data/txt_parser.dart';
import 'package:readlive/features/reader/data/epub_parser.dart';
import 'package:readlive/features/reader/data/pdf_parser.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';
import 'package:uuid/uuid.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksStreamProvider);
    final bookCount = booksAsync.whenData((books) => books.length);
    final statsAsync = ref.watch(readingStatsProvider);
    final avatarPath = ref.watch(avatarPathProvider);
    final signature = ref.watch(signatureProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          // Avatar + Signature header
          GestureDetector(
            onTap: () => _pickAvatar(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: avatarPath != null && File(avatarPath).existsSync()
                        ? FileImage(File(avatarPath))
                        : null,
                    child: avatarPath == null || !File(avatarPath).existsSync()
                        ? Icon(Icons.person, size: 44, color: Theme.of(context).colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _editSignature(context, signature),
                    child: Text(
                      signature,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    icon: Icons.book,
                    label: '书籍',
                    value: '${bookCount.value ?? 0}',
                  ),
                  _StatItem(
                    icon: Icons.access_time,
                    label: '阅读时长',
                    value: statsAsync.when(
                      loading: () => '...',
                      error: (_, __) => '0分钟',
                      data: (stats) => stats.totalFormatted,
                    ),
                  ),
                  _StatItem(
                    icon: Icons.trending_up,
                    label: '今日',
                    value: statsAsync.when(
                      loading: () => '...',
                      error: (_, __) => '0字',
                      data: (stats) => stats.todayWordsFormatted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Today's reading time
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) {
              if (stats.todaySeconds <= 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('今日阅读'),
                    trailing: Text(
                      stats.todayFormatted,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // Menu items
          _MenuTile(
            icon: Icons.import_export,
            title: '本地文件导入',
            subtitle: '导入 TXT / EPUB 文件',
            onTap: _importFile,
          ),
          _MenuTile(
            icon: Icons.cloud_outlined,
            title: '书源管理',
            subtitle: '管理网络书源规则',
            onTap: () => context.push('/sources'),
          ),
          _MenuTile(
            icon: Icons.backup_outlined,
            title: '本地备份/恢复',
            subtitle: '备份或恢复阅读数据',
            onTap: () => _showBackupRestoreDialog(context),
          ),
          _MenuTile(
            icon: Icons.bar_chart_outlined,
            title: '阅读统计',
            subtitle: '查看阅读趋势与数据',
            onTap: () => context.push('/stats'),
          ),

          const Divider(),

          _MenuTile(
            icon: Icons.settings_outlined,
            title: '设置',
            onTap: () => context.push('/settings'),
          ),
          _MenuTile(
            icon: Icons.help_outline,
            title: '帮助与关于',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ReadLive',
                applicationVersion: '1.0.0',
                children: [
                  const Text('一款纯本地优先的小说阅读器\n无广告、无付费、无数据上传'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'epub', 'pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final f = File(filePath);
      if (!await f.exists()) {
        _showError('文件不存在');
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
      } else {
        _showError('不支持的文件格式');
      }
    } catch (e) {
      _showError('导入失败: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
    }
  }

  Future<void> _pickAvatar(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final ext = filePath.split('.').last;
      final destPath = '${avatarDir.path}/avatar_${const Uuid().v4()}.$ext';
      await File(filePath).copy(destPath);

      ref.read(avatarPathProvider.notifier).setPath(destPath);
    } catch (e) {
      _showError('设置头像失败: $e');
    }
  }

  Future<void> _editSignature(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑签名'),
        content: TextField(
          controller: controller,
          maxLength: 30,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入个性签名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      ref.read(signatureProvider.notifier).setSignature(result);
    }
  }

  void _showBackupRestoreDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('备份与恢复',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('备份数据'),
              subtitle: const Text('导出数据库到文件'),
              onTap: () {
                Navigator.pop(ctx);
                _backupDatabase();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('恢复数据'),
              subtitle: const Text('从备份文件恢复'),
              onTap: () {
                Navigator.pop(ctx);
                _restoreDatabase();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _backupDatabase() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${appDir.path}/readlive.sqlite');

      if (!await dbFile.exists()) {
        _showError('数据库文件不存在');
        return;
      }

      final repo = ref.read(bookRepositoryProvider);
      final books = await repo.getAllBooks();

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存备份文件',
        fileName: 'readlive_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (savePath == null) return;

      final archive = Archive();

      // Add metadata
      final metadata = jsonEncode({
        'version': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'bookCount': books.length,
      });
      final metaBytes = utf8.encode(metadata);
      archive.addFile(ArchiveFile('metadata.json', metaBytes.length, metaBytes));

      // Add database
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile('readlive.sqlite', dbBytes.length, dbBytes));

      // Add cover images
      final coversDir = Directory('${appDir.path}/covers');
      if (await coversDir.exists()) {
        await for (final file in coversDir.list(recursive: true)) {
          if (file is File) {
            final relativePath = 'covers/${file.path.substring(coversDir.path.length + 1)}';
            final bytes = await file.readAsBytes();
            archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
          }
        }
      }

      // Add manga images
      final mangaDir = Directory('${appDir.path}/manga');
      if (await mangaDir.exists()) {
        await for (final file in mangaDir.list(recursive: true)) {
          if (file is File) {
            final relativePath = 'manga/${file.path.substring(mangaDir.path.length + 1)}';
            final bytes = await file.readAsBytes();
            archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
          }
        }
      }

      // Add book_images
      final bookImagesDir = Directory('${appDir.path}/book_images');
      if (await bookImagesDir.exists()) {
        await for (final file in bookImagesDir.list(recursive: true)) {
          if (file is File) {
            final relativePath = 'book_images/${file.path.substring(bookImagesDir.path.length + 1)}';
            final bytes = await file.readAsBytes();
            archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
          }
        }
      }

      // Encode and save
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        _showError('备份编码失败');
        return;
      }
      await File(savePath).writeAsBytes(zipBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份成功，共 ${books.length} 本书')),
        );
      }
    } catch (e) {
      _showError('备份失败: $e');
    }
  }

  Future<void> _restoreDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final backupFile = File(filePath);
      if (!await backupFile.exists()) {
        _showError('备份文件不存在');
        return;
      }

      // Decode zip and read metadata
      final zipBytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      final metadataFile = archive.findFile('metadata.json');
      if (metadataFile == null) {
        _showError('无效的备份文件（缺少 metadata.json）');
        return;
      }

      final metadata = jsonDecode(utf8.decode(metadataFile.content as List<int>));
      final backupVersion = metadata['version'] as String? ?? '未知';
      final createdAt = metadata['createdAt'] as String? ?? '未知';
      final bookCount = metadata['bookCount'] as int? ?? 0;

      // Confirm before restoring
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('恢复数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('恢复将覆盖当前所有数据，确定继续吗？'),
              const SizedBox(height: 12),
              Text('版本: $backupVersion', style: Theme.of(ctx).textTheme.bodySmall),
              Text('备份时间: ${createdAt.substring(0, 19).replaceAll('T', ' ')}', style: Theme.of(ctx).textTheme.bodySmall),
              Text('书籍数量: $bookCount', style: Theme.of(ctx).textTheme.bodySmall),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定恢复'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final appDir = await getApplicationDocumentsDirectory();

      // Close the current database
      ref.read(databaseProvider).close();

      // Extract all files from backup
      for (final file in archive) {
        if (file.isFile) {
          final outFile = File('${appDir.path}/${file.name}');
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('恢复成功，请重启应用')),
        );
      }
    } catch (e) {
      _showError('恢复失败: $e');
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
