import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
          const Divider(),
          const _SectionHeader(title: '阅读'),
          ListTile(
            leading: const Icon(Icons.font_download),
            title: const Text('阅读设置'),
            subtitle: const Text('字号、行间距、翻页效果'),
            onTap: () {
              // Phase 3: reading settings
            },
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
