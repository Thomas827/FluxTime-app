import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluxtime/providers/energy_provider.dart';
import 'package:fluxtime/models/energy_level.dart';

/// 精力管理页面
class EnergyScreen extends StatefulWidget {
  const EnergyScreen({super.key});

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> {
  DateTime _selectedDate = DateTime.now();
  int _averageDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnergyProvider>().loadEnergyLevels();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('精力管理'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_view_day),
            onSelected: (days) {
              setState(() {
                _averageDays = days;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 3, child: Text('近3天平均')),
              const PopupMenuItem(value: 7, child: Text('近7天平均')),
              const PopupMenuItem(value: 14, child: Text('近14天平均')),
            ],
          ),
        ],
      ),
      body: Consumer<EnergyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final todayRecords = provider.getEnergyByDate(_selectedDate);
          final averageCurve = provider.getAverageCurve(_averageDays);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日期选择
                _buildDateSelector(),
                const SizedBox(height: 16),

                // 今日精力曲线
                _buildTodayCurveCard(context, todayRecords),
                const SizedBox(height: 24),

                // 多日平均曲线
                _buildAverageCurveCard(context, averageCurve),
                const SizedBox(height: 24),

                // 精力时段编辑
                _buildEnergyEditor(context, provider, todayRecords),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _formatDate(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _selectedDate.isBefore(DateTime.now())
              ? () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildTodayCurveCard(BuildContext context, List<EnergyLevel> records) {
    // 构建今日每小时精力数据
    List<double> hourlyLevels = List.filled(24, 0.5); // 默认中间值
    List<int> counts = List.filled(24, 0);

    for (var record in records) {
      int hour = record.timeSlot ~/ 12;
      hourlyLevels[hour] += record.level;
      counts[hour]++;
    }

    for (int i = 0; i < 24; i++) {
      if (counts[i] > 0) {
        hourlyLevels[i] = hourlyLevels[i] / (counts[i] + 1);
      }
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
                  '今日精力曲线',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${records.length}个记录点',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: _buildLineChart(hourlyLevels, Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageCurveCard(BuildContext context, DailyEnergyCurve curve) {
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
                  '近$_averageDays天平均曲线',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${curve.highEnergyHours.length}个高精力时段',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '高精力时段: ${curve.recommendedPeriods}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: _buildLineChart(curve.averageLevels, Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<double> data, Color color) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 0.5,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('低', style: TextStyle(fontSize: 10));
                if (value == 1) return const Text('高', style: TextStyle(fontSize: 10));
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyEditor(
    BuildContext context,
    EnergyProvider provider,
    List<EnergyLevel> todayRecords,
  ) {
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
                  '标记精力时段',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () => _quickFill(provider),
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: const Text('快速填充'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '点击时段标记精力高低（绿色=高精力，灰色=低精力）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            
            // 时段网格
            _buildTimeSlotGrid(provider, todayRecords),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotGrid(EnergyProvider provider, List<EnergyLevel> records) {
    // 将一天分为24个小时段
    return Column(
      children: List.generate(24, (hour) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // 时间标签
              SizedBox(
                width: 50,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              // 12个5分钟时段
              Expanded(
                child: Row(
                  children: List.generate(12, (slot) {
                    final timeSlot = hour * 12 + slot;
                    final record = records.where((r) => r.timeSlot == timeSlot).firstOrNull;
                    final level = record?.level ?? -1;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleSlot(provider, timeSlot, level),
                        child: Container(
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: level == 1
                                ? Colors.green
                                : level == 0
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _toggleSlot(EnergyProvider provider, int timeSlot, int currentLevel) {
    // 循环切换: 无 -> 高 -> 低 -> 无
    int newLevel;
    if (currentLevel == -1) {
      newLevel = 1; // 无 -> 高
    } else if (currentLevel == 1) {
      newLevel = 0; // 高 -> 低
    } else {
      newLevel = -1; // 低 -> 删除
    }

    if (newLevel == -1) {
      // 删除记录（设置为低精力作为清除）
      provider.setEnergyLevel(
        date: _selectedDate,
        timeSlot: timeSlot,
        level: 0,
      );
    } else {
      provider.setEnergyLevel(
        date: _selectedDate,
        timeSlot: timeSlot,
        level: newLevel,
      );
    }
  }

  void _quickFill(EnergyProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('快速填充'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wb_sunny, color: Colors.orange),
              title: const Text('上午高精力'),
              onTap: () {
                _fillRange(provider, 8, 12, 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.nights_stay, color: Colors.indigo),
              title: const Text('下午高精力'),
              onTap: () {
                _fillRange(provider, 14, 18, 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bedtime, color: Colors.grey),
              title: const Text('全天低精力'),
              onTap: () {
                _fillRange(provider, 0, 24, 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear, color: Colors.red),
              title: const Text('清除今日数据'),
              onTap: () {
                provider.clearDateRecords(_selectedDate);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _fillRange(EnergyProvider provider, int startHour, int endHour, int level) {
    Map<int, int> slotLevels = {};
    for (int hour = startHour; hour < endHour; hour++) {
      for (int slot = 0; slot < 12; slot++) {
        slotLevels[hour * 12 + slot] = level;
      }
    }
    provider.setEnergyLevelsBatch(date: _selectedDate, slotLevels: slotLevels);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    
    if (isToday) return '今天';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
