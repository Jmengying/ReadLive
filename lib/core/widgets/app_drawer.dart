import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';
import 'package:uuid/uuid.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final avatarPath = ref.watch(avatarPathProvider);
    final signature = ref.watch(signatureProvider);
    final statsAsync = ref.watch(readingStatsProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header: avatar + tagline
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickAvatar(context, ref),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: avatarPath != null &&
                              File(avatarPath).existsSync()
                          ? FileImage(File(avatarPath))
                          : null,
                      child: avatarPath == null ||
                              !File(avatarPath).existsSync()
                          ? Icon(Icons.person,
                              size: 40,
                              color: theme.colorScheme.onPrimaryContainer)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _editSignature(context, ref, signature),
                    child: Text(
                      signature,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Reading time summary
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) {
                if (stats.totalSeconds <= 0) return const SizedBox.shrink();
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '阅读时长 ${stats.totalFormatted}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 1),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    title: '设置',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.palette_outlined,
                    title: '外观',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.bar_chart_outlined,
                    title: '统计',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/stats');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.backup_outlined,
                    title: '数据备份',
                    onTap: () {
                      Navigator.pop(context);
                      _showBackupRestoreDialog(context, ref);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.cloud_outlined,
                    title: '书源管理',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/sources');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.folder_outlined,
                    title: '分组管理',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/groups');
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20),
                  _DrawerTile(
                    icon: Icons.info_outline,
                    title: '关于',
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'ReadLive',
                        applicationVersion: '1.0.0',
                        children: [
                          const Text(
                              '一款纯本地优先的小说阅读器\n无广告、无付费、无数据上传'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
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
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('设置头像失败: $e')));
      }
    }
  }

  Future<void> _editSignature(
      BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑签名'),
        content: TextField(
          controller: controller,
          maxLength: 30,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入个性签名'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('确定')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      ref.read(signatureProvider.notifier).setSignature(result);
    }
  }

  void _showBackupRestoreDialog(BuildContext context, WidgetRef ref) {
    final rootContext = context;
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
                _doBackup(rootContext, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('恢复数据'),
              subtitle: const Text('从备份文件恢复'),
              onTap: () {
                Navigator.pop(ctx);
                _doRestore(rootContext, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _doBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${appDir.path}/readlive.sqlite');

      if (!await dbFile.exists()) {
        messenger.showSnackBar(const SnackBar(content: Text('数据库文件不存在')));
        return;
      }

      messenger.showSnackBar(const SnackBar(content: Text('正在备份...')));

      final repo = ref.read(bookRepositoryProvider);
      final books = await repo.getAllBooks();

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存备份文件',
        fileName:
            'readlive_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (savePath == null) return;

      final archive = Archive();

      // Metadata
      final metadata = jsonEncode({
        'version': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'bookCount': books.length,
      });
      final metaBytes = utf8.encode(metadata);
      archive.addFile(
          ArchiveFile('metadata.json', metaBytes.length, metaBytes));

      // Database
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(
          ArchiveFile('readlive.sqlite', dbBytes.length, dbBytes));

      // Helper to add directory
      Future<void> addDir(String name) async {
        final dir = Directory('${appDir.path}/$name');
        if (await dir.exists()) {
          await for (final file in dir.list(recursive: true)) {
            if (file is File) {
              final relPath =
                  '$name/${file.path.substring(dir.path.length + 1)}';
              final bytes = await file.readAsBytes();
              archive.addFile(ArchiveFile(relPath, bytes.length, bytes));
            }
          }
        }
      }

      await addDir('covers');
      await addDir('manga');
      await addDir('book_images');
      await addDir('avatars');

      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        messenger.showSnackBar(const SnackBar(content: Text('备份编码失败')));
        return;
      }

      await File(savePath).writeAsBytes(zipBytes);
      messenger
          .showSnackBar(SnackBar(content: Text('备份成功: ${books.length} 本书')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('备份失败: $e')));
    }
  }

  Future<void> _doRestore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
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
        messenger.showSnackBar(const SnackBar(content: Text('备份文件不存在')));
        return;
      }

      final zipBytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      final metadataFile = archive.findFile('metadata.json');
      if (metadataFile == null) {
        messenger.showSnackBar(const SnackBar(content: Text('无效的备份文件')));
        return;
      }

      final metadata =
          jsonDecode(utf8.decode(metadataFile.content as List<int>));
      final bookCount = metadata['bookCount'] as int? ?? 0;
      final createdAt = (metadata['createdAt'] as String? ?? '');
      final timeStr = createdAt.length >= 19
          ? createdAt.substring(0, 19).replaceAll('T', ' ')
          : createdAt;

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('恢复数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('恢复将覆盖当前所有数据，确定继续吗？'),
              if (timeStr.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('备份时间: $timeStr',
                    style: Theme.of(ctx).textTheme.bodySmall),
              ],
              Text('书籍数量: $bookCount',
                  style: Theme.of(ctx).textTheme.bodySmall),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('确定恢复')),
          ],
        ),
      );

      if (confirmed != true) return;

      messenger.showSnackBar(const SnackBar(content: Text('正在恢复...')));

      final appDir = await getApplicationDocumentsDirectory();

      // Close database
      try {
        ref.read(databaseProvider).close();
      } catch (_) {}

      // Extract files
      for (final file in archive) {
        if (file.isFile) {
          final outFile = File('${appDir.path}/${file.name}');
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        }
      }

      messenger.showSnackBar(const SnackBar(
          content: Text('恢复成功，请重启应用'),
          duration: Duration(seconds: 5)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('恢复失败: $e')));
    }
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading:
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
    );
  }
}
