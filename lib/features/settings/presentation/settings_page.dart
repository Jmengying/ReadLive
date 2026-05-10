import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readlive/core/theme/app_theme.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _dbSize = '计算中...';
  String _coversSize = '计算中...';
  String _mangaSize = '计算中...';

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbSize = await _dirSize(File('${appDir.path}/readlive.sqlite'));
    final coversSize = await _dirSize(Directory('${appDir.path}/covers'));
    final mangaSize = await _dirSize(Directory('${appDir.path}/manga'));
    final bookImagesSize = await _dirSize(Directory('${appDir.path}/book_images'));
    if (mounted) {
      setState(() {
        _dbSize = _formatBytes(dbSize);
        _coversSize = _formatBytes(coversSize);
        _mangaSize = _formatBytes(mangaSize + bookImagesSize);
      });
    }
  }

  Future<int> _dirSize(FileSystemEntity entity) async {
    if (entity is File) {
      return await entity.exists() ? await entity.length() : 0;
    }
    if (entity is Directory) {
      if (!await entity.exists()) return 0;
      var total = 0;
      await for (final child in entity.list(recursive: true)) {
        if (child is File) {
          total += await child.length();
        }
      }
      return total;
    }
    return 0;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _clearCache() async {
    final appDir = await getApplicationDocumentsDirectory();
    var cleared = 0;

    // Clear book_images cache (EPUB inline images can be re-extracted)
    final bookImagesDir = Directory('${appDir.path}/book_images');
    if (await bookImagesDir.exists()) {
      cleared += await _dirSize(bookImagesDir);
      await bookImagesDir.delete(recursive: true);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已清理缓存 ${_formatBytes(cleared)}')),
      );
      _loadStorageStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader(title: '外观'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('主题模式'),
            subtitle: Text(_themeModeLabel(themeMode)),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题色'),
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
            ),
            onTap: () => _showAccentColorDialog(context, ref, accentColor),
          ),
          const Divider(),
          const _SectionHeader(title: '存储'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('数据库'),
            trailing: Text(_dbSize, style: Theme.of(context).textTheme.bodyMedium),
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('封面图片'),
            trailing: Text(_coversSize, style: Theme.of(context).textTheme.bodyMedium),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('漫画与书籍图片'),
            trailing: Text(_mangaSize, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: _clearCache,
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('清理缓存'),
            ),
          ),
          const Divider(),
          const _SectionHeader(title: '其他'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('ReadLive v1.0.0'),
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

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return '浅色模式';
      case ThemeMode.dark: return '深色模式';
      case ThemeMode.system: return '跟随系统';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setThemeMode(v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色模式'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setThemeMode(v!);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色模式'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setThemeMode(v!);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccentColorDialog(BuildContext context, WidgetRef ref, Color current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('主题色'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppTheme.accentColors.map((color) {
            final isSelected = color.value == current.value;
            return GestureDetector(
              onTap: () {
                ref.read(accentColorProvider.notifier).setColor(color);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withAlpha(100), blurRadius: 8)]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
