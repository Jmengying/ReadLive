import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksStreamProvider);
    final bookCount = booksAsync.whenData((books) => books.length);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          // Stats card
          Card(
            margin: const EdgeInsets.all(16),
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
                    value: '0分钟',
                  ),
                  _StatItem(
                    icon: Icons.trending_up,
                    label: '今日',
                    value: '0字',
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Menu items
          _MenuTile(
            icon: Icons.import_export,
            title: '本地文件导入',
            onTap: () {
              // Handled via bookshelf + button
            },
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
            onTap: () {
              // Phase 4: backup
            },
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
