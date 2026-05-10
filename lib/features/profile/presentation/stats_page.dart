import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:readlive/features/profile/presentation/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const SizedBox(height: 24),
            // Weekly chart
            _buildSectionTitle(context, '近7天阅读趋势'),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _buildWeeklyChart(stats.weeklyData),
            ),
            const SizedBox(height: 24),
            // Monthly chart
            _buildSectionTitle(context, '近30天阅读趋势'),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _buildMonthlyChart(stats.monthlyData),
            ),
            const SizedBox(height: 24),
            // Book distribution
            if (stats.bookDistribution.isNotEmpty) ...[
              _buildSectionTitle(context, '书籍阅读分布'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _buildPieChart(stats.bookDistribution),
              ),
              const SizedBox(height: 8),
              ...stats.bookDistribution.map((b) => ListTile(
                dense: true,
                title: Text(b.bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(_formatDuration(b.totalSeconds)),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, ReadingStatsData stats) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.local_fire_department,
          label: '连续阅读',
          value: '${stats.currentStreak}天',
          color: Colors.orange,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          icon: Icons.timer,
          label: '总阅读时长',
          value: _formatDuration(stats.totalSeconds),
          color: Colors.blue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          icon: Icons.trending_up,
          label: '日均阅读',
          value: '${stats.avgDailyMinutes.toStringAsFixed(0)}分钟',
          color: Colors.green,
        )),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleSmall);
  }

  Widget _buildWeeklyChart(List<DailyReading> data) {
    if (data.isEmpty) return const Center(child: Text('暂无数据'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.fold<double>(0, (max, d) => d.minutes > max ? d.minutes.toDouble() : max) * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[group.x].date.month}/${data[group.x].date.day}\n',
                const TextStyle(color: Colors.white, fontSize: 12),
                children: [
                  TextSpan(
                    text: '${rod.toY.toInt()}分钟',
                    style: const TextStyle(color: Colors.yellow, fontSize: 12),
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
                return Text('${d.date.day}',
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.minutes.toDouble(),
              color: Colors.blue,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildMonthlyChart(List<DailyReading> data) {
    if (data.isEmpty) return const Center(child: Text('暂无数据'));

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: data.fold<double>(0, (max, d) => d.minutes > max ? d.minutes.toDouble() : max) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) =>
              FlSpot(e.key.toDouble(), e.value.minutes.toDouble())
            ).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withAlpha(40),
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
                  return Text('${data[idx].date.month}/${data[idx].date.day}',
                      style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart(List<BookReadingTime> data) {
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red,
    ];

    return PieChart(
      PieChartData(
        sections: data.asMap().entries.map((e) => PieChartSectionData(
          value: e.value.totalSeconds.toDouble(),
          title: '${(e.value.totalSeconds / 60).toInt()}分',
          color: colors[e.key % colors.length],
          radius: 60,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        )).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds秒';
    if (seconds < 3600) return '${seconds ~/ 60}分钟';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return mins > 0 ? '$hours时$mins分' : '$hours小时';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
