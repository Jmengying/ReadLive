import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:readlive/features/profile/presentation/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(statsProvider);

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
            const SizedBox(height: 20),
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
                final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
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
        // Legend
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
