import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:readlive/features/profile/presentation/stats_provider.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  @override
  void initState() {
    super.initState();
    // Invalidate stats when refresh counter changes
    ref.listenManual(statsRefreshProvider, (prev, next) {
      if (prev != next) {
        ref.invalidate(statsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(statsProvider);
    final dailyGoal = ref.watch(dailyGoalProvider);
    final goalNotify = ref.watch(goalNotifyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('阅读统计')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overview cards
            _buildOverviewCards(context, stats),
            const SizedBox(height: 16),
            // Book stats row
            _buildBookStatsRow(context, stats),
            const SizedBox(height: 16),
            // Reading goal
            _buildGoalCard(context, ref, stats, dailyGoal, goalNotify),
            const SizedBox(height: 16),
            // Weekly chart
            _buildChartCard(
              context,
              title: '近 7 天阅读趋势',
              child: SizedBox(
                height: 180,
                child: _buildWeeklyChart(context, stats.weeklyData),
              ),
            ),
            const SizedBox(height: 16),
            // Monthly chart
            _buildChartCard(
              context,
              title: '近 30 天阅读趋势',
              child: SizedBox(
                height: 180,
                child: _buildMonthlyChart(context, stats.monthlyData),
              ),
            ),
            const SizedBox(height: 16),
            // Book distribution
            if (stats.bookDistribution.isNotEmpty) ...[
              _buildChartCard(
                context,
                title: '书籍阅读分布',
                child: SizedBox(
                  height: 180,
                  child: _buildPieChart(stats.bookDistribution),
                ),
              ),
              const SizedBox(height: 8),
              ...stats.bookDistribution.map((b) => _buildBookItem(context, b)),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, ReadingStatsData stats) {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            label: '连续阅读',
            value: '${stats.currentStreak}',
            unit: '天',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewCard(
            icon: Icons.timer_outlined,
            iconColor: Colors.blue,
            label: '总阅读时长',
            value: _formatDurationShort(stats.totalSeconds),
            unit: '',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OverviewCard(
            icon: Icons.trending_up,
            iconColor: Colors.green,
            label: '日均阅读',
            value: '${stats.avgDailyMinutes.toStringAsFixed(0)}',
            unit: '分钟',
          ),
        ),
      ],
    );
  }

  Widget _buildBookStatsRow(BuildContext context, ReadingStatsData stats) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BookStatItem(
            icon: Icons.menu_book,
            label: '在读',
            value: '${stats.readingBooks}',
            color: Colors.blue,
          ),
          Container(width: 1, height: 32, color: theme.dividerTheme.color),
          _BookStatItem(
            icon: Icons.check_circle_outline,
            label: '读完',
            value: '${stats.finishedBooks}',
            color: Colors.green,
          ),
          Container(width: 1, height: 32, color: theme.dividerTheme.color),
          _BookStatItem(
            icon: Icons.history,
            label: '阅读次数',
            value: '${stats.sessionCount}',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref,
      ReadingStatsData stats, int dailyGoal, bool goalNotify) {
    final theme = Theme.of(context);
    final todayMinutes = stats.todaySeconds ~/ 60;
    final goalReached = dailyGoal > 0 && todayMinutes >= dailyGoal;
    final progress = dailyGoal > 0
        ? (todayMinutes / dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '每日阅读目标',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showGoalSettingsDialog(context, dailyGoal, goalNotify),
                child: Icon(Icons.settings_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dailyGoal == 0) ...[
            Text(
              '未设置目标',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('设置阅读目标'),
                onPressed: () => _showGoalSettingsDialog(context, dailyGoal, goalNotify),
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$todayMinutes',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: goalReached
                        ? Colors.green
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  ' / $dailyGoal 分钟',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (goalReached) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '已达成',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: goalReached ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showGoalSettingsDialog(
      BuildContext context, int currentGoal, bool currentNotify) {
    final controller =
        TextEditingController(text: currentGoal > 0 ? '$currentGoal' : '');
    bool notify = currentNotify;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('设置阅读目标'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '每日阅读目标（分钟）',
                  hintText: '例如：30',
                  suffixText: '分钟',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Text('达成目标时弹窗提醒')),
                  Switch(
                    value: notify,
                    onChanged: (v) => setDialogState(() => notify = v),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (currentGoal > 0)
              TextButton(
                onPressed: () {
                  ref.read(dailyGoalProvider.notifier).setGoal(0);
                  ref.read(goalNotifyProvider.notifier).setEnabled(false);
                  Navigator.pop(ctx);
                },
                child: const Text('清除目标',
                    style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final minutes = int.tryParse(controller.text) ?? 0;
                ref.read(dailyGoalProvider.notifier).setGoal(minutes);
                ref.read(goalNotifyProvider.notifier).setEnabled(notify);
                Navigator.pop(ctx);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context,
      {required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<DailyReading> data) {
    if (data.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final theme = Theme.of(context);
    final maxY = data.fold<double>(
            0, (max, d) => d.minutes > max ? d.minutes.toDouble() : max) *
        1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY : 10,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[group.x].date.month}/${data[group.x].date.day}\n',
                const TextStyle(color: Colors.white, fontSize: 12),
                children: [
                  TextSpan(
                    text: '${rod.toY.toInt()} 分钟',
                    style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final d = data[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.date.month}/${d.date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          final isToday = e.key == data.length - 1;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.minutes.toDouble(),
                color: isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.4),
                width: 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyChart(BuildContext context, List<DailyReading> data) {
    if (data.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final theme = Theme.of(context);
    final maxY = data.fold<double>(
            0, (max, d) => d.minutes > max ? d.minutes.toDouble() : max) *
        1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY > 0 ? maxY : 10,
        lineBarsData: [
          LineChartBarData(
            spots: data
                .asMap()
                .entries
                .map((e) =>
                    FlSpot(e.key.toDouble(), e.value.minutes.toDouble()))
                .toList(),
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${data[idx].date.month}/${data[idx].date.day}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart(List<BookReadingTime> data) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: data.asMap().entries.map((e) {
                final percent = e.value.totalSeconds /
                    data.fold<int>(
                        0, (sum, b) => sum + b.totalSeconds) *
                    100;
                return PieChartSectionData(
                  value: e.value.totalSeconds.toDouble(),
                  title: '${percent.toStringAsFixed(0)}%',
                  color: colors[e.key % colors.length],
                  radius: 55,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 25,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: data.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[e.key % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      e.value.bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBookItem(BuildContext context, BookReadingTime book) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.book_outlined,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              book.bookTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            _formatDuration(book.totalSeconds),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds 秒';
    if (seconds < 3600) return '${seconds ~/ 60} 分钟';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return mins > 0 ? '$hours 小时 $mins 分钟' : '$hours 小时';
  }

  String _formatDurationShort(int seconds) {
    if (seconds < 60) return '${seconds}秒';
    if (seconds < 3600) return '${seconds ~/ 60}分';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return mins > 0 ? '$hours时$mins分' : '$hours时';
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _OverviewCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BookStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
