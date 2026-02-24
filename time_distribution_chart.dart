import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluxtime/models/time_record.dart';

/// 时间分布图表组件
class TimeDistributionChart extends StatelessWidget {
  final Map<TimeCategory, int> timeByCategory;
  final int totalMinutes;

  const TimeDistributionChart({
    super.key,
    required this.timeByCategory,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    if (totalMinutes == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  '暂无时间数据',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '时间分布',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _formatTotalTime(totalMinutes),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // 饼图
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _buildPieChartSections(),
                      ),
                    ),
                  ),
                  // 图例
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: TimeCategory.values.map((category) {
                      final minutes = timeByCategory[category] ?? 0;
                      final percentage = totalMinutes > 0
                          ? (minutes / totalMinutes * 100).toStringAsFixed(0)
                          : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(category.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${category.label}: $percentage%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return TimeCategory.values.map((category) {
      final minutes = timeByCategory[category] ?? 0;
      final percentage = totalMinutes > 0 ? minutes / totalMinutes : 0;

      return PieChartSectionData(
        color: Color(category.color),
        value: minutes.toDouble(),
        title: percentage > 0.05 ? '${(percentage * 100).toStringAsFixed(0)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  String _formatTotalTime(int minutes) {
    if (minutes < 60) return '${minutes}分钟';
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return mins > 0 ? '${hours}小时${mins}分钟' : '${hours}小时';
  }
}
