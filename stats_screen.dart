import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluxtime/providers/task_provider.dart';
import 'package:fluxtime/providers/time_record_provider.dart';
import 'package:fluxtime/providers/energy_provider.dart';
import 'package:fluxtime/models/time_record.dart';
import 'package:fluxtime/services/ucevi_service.dart';

/// 统计页面
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedPeriod = 7; // 7天或30天

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<TaskProvider>().loadTasks();
    context.read<TimeRecordProvider>().loadRecords();
    context.read<EnergyProvider>().loadEnergyLevels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
        actions: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7天')),
              ButtonSegment(value: 30, label: Text('30天')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (Set<int> selection) {
              setState(() {
                _selectedPeriod = selection.first;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer3<TaskProvider, TimeRecordProvider, EnergyProvider>(
        builder: (context, taskProvider, timeProvider, energyProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 任务统计概览
                _buildTaskOverview(context, taskProvider),
                const SizedBox(height: 24),

                // UCEVI评分分布
                _buildScoreDistribution(context, taskProvider),
                const SizedBox(height: 24),

                // 时间使用统计
                _buildTimeStats(context, timeProvider),
                const SizedBox(height: 24),

                // 精力趋势
                _buildEnergyTrend(context, energyProvider),
                const SizedBox(height: 24),

                // 效率分析
                _buildEfficiencyAnalysis(context, taskProvider, timeProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskOverview(BuildContext context, TaskProvider taskProvider) {
    final summary = UceviService.instance.getTaskSummary(taskProvider.tasks);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '任务概览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildOverviewItem(
                  context,
                  '总任务',
                  summary.totalTasks.toString(),
                  Icons.list,
                  Colors.blue,
                ),
                _buildOverviewItem(
                  context,
                  '待完成',
                  summary.pendingTasks.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildOverviewItem(
                  context,
                  '已完成',
                  summary.completedTasks.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildOverviewItem(
                  context,
                  '高优先',
                  summary.highPriorityCount.toString(),
                  Icons.priority_high,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 完成率进度条
            Row(
              children: [
                Text(
                  '完成率',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: taskProvider.tasks.isEmpty
                          ? 0
                          : summary.completedTasks / summary.totalTasks,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(taskProvider.tasks.isEmpty ? 0 : summary.completedTasks / summary.totalTasks * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistribution(BuildContext context, TaskProvider taskProvider) {
    final pendingTasks = taskProvider.pendingTasks;
    
    // 统计各分数段任务数量
    int high = 0, medium = 0, low = 0;
    for (var task in pendingTasks) {
      if (task.uceviScore >= 6) {
        high++;
      } else if (task.uceviScore >= 4) {
        medium++;
      } else {
        low++;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UCEVI评分分布',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (pendingTasks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('暂无待办任务'),
                ),
              )
            else
              SizedBox(
                height: 150,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (high > medium ? high : medium).toDouble() + 1,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return const Text('高优先');
                              case 1:
                                return const Text('中优先');
                              case 2:
                                return const Text('低优先');
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: high.toDouble(),
                            color: Colors.red,
                            width: 40,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: medium.toDouble(),
                            color: Colors.orange,
                            width: 40,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: low.toDouble(),
                            color: Colors.grey,
                            width: 40,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStats(BuildContext context, TimeRecordProvider timeProvider) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedPeriod));
    final records = timeProvider.getRecordsByDateRange(startDate, now);

    // 按分类统计
    Map<TimeCategory, int> categoryTotals = {};
    for (var category in TimeCategory.values) {
      categoryTotals[category] = 0;
    }
    for (var record in records) {
      categoryTotals[record.category] = 
          (categoryTotals[record.category] ?? 0) + record.durationMinutes;
    }

    int totalMinutes = categoryTotals.values.fold(0, (sum, v) => sum + v);

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
                  '时间使用统计',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '共 ${_formatMinutes(totalMinutes)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...TimeCategory.values.map((category) {
              final minutes = categoryTotals[category] ?? 0;
              final percentage = totalMinutes > 0 ? minutes / totalMinutes : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                            Text(category.label),
                          ],
                        ),
                        Text(
                          _formatMinutes(minutes),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(category.color),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyTrend(BuildContext context, EnergyProvider energyProvider) {
    final curve = energyProvider.getAverageCurve(_selectedPeriod);
    final highEnergyHours = curve.highEnergyHours;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '精力趋势分析',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.battery_charging_full,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${highEnergyHours.length}小时',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '高精力时段',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          curve.recommendedPeriods.split(',').length.toString(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '高效时段',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '推荐工作时段: ${curve.recommendedPeriods}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyAnalysis(
    BuildContext context,
    TaskProvider taskProvider,
    TimeRecordProvider timeProvider,
  ) {
    final summary = UceviService.instance.getTaskSummary(taskProvider.tasks);
    final now = DateTime.now();
    final todayRecords = timeProvider.getRecordsByDate(now);
    final todayMinutes = todayRecords.fold(0, (sum, r) => sum + r.durationMinutes);

    // 计算效率评分
    double efficiencyScore = 0;
    if (summary.totalTasks > 0) {
      double completionRate = summary.completedTasks / summary.totalTasks;
      double highPriorityRate = summary.pendingTasks > 0
          ? summary.highPriorityCount / summary.pendingTasks
          : 0;
      
      efficiencyScore = (completionRate * 50 + (1 - highPriorityRate) * 30 + 
          (todayMinutes > 120 ? 20 : todayMinutes / 120 * 20));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '效率分析',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: efficiencyScore / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getEfficiencyColor(efficiencyScore),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              efficiencyScore.toStringAsFixed(0),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getEfficiencyColor(efficiencyScore),
                                  ),
                            ),
                            Text(
                              '分',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEfficiencyTip(efficiencyScore),
          ],
        ),
      ),
    );
  }

  Color _getEfficiencyColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEfficiencyTip(double score) {
    String tip;
    IconData icon;
    Color color;

    if (score >= 80) {
      tip = '效率优秀！继续保持高效工作状态';
      icon = Icons.emoji_events;
      color = Colors.green;
    } else if (score >= 60) {
      tip = '效率良好，可以尝试完成更多高优先级任务';
      icon = Icons.thumb_up;
      color = Colors.blue;
    } else if (score >= 40) {
      tip = '效率一般，建议关注高优先级任务';
      icon = Icons.info;
      color = Colors.orange;
    } else {
      tip = '效率较低，建议制定计划并专注重要任务';
      icon = Icons.warning;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}分钟';
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return mins > 0 ? '${hours}h${mins}m' : '${hours}h';
  }
}
