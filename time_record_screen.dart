import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluxtime/providers/time_record_provider.dart';
import 'package:fluxtime/models/time_record.dart';
import 'package:fluxtime/widgets/time_distribution_chart.dart';

/// 时间记录页面
class TimeRecordScreen extends StatefulWidget {
  const TimeRecordScreen({super.key});

  @override
  State<TimeRecordScreen> createState() => _TimeRecordScreenState();
}

class _TimeRecordScreenState extends State<TimeRecordScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimeRecordProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时间记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Consumer<TimeRecordProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final todayRecords = provider.getRecordsByDate(_selectedDate);
          final timeByCategory = provider.getTimeByCategory(date: _selectedDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日期显示
                _buildDateHeader(),
                const SizedBox(height: 16),

                // 时间分布图表
                TimeDistributionChart(
                  timeByCategory: timeByCategory,
                  totalMinutes: todayRecords.fold(
                    0,
                    (sum, r) => sum + r.durationMinutes,
                  ),
                ),
                const SizedBox(height: 24),

                // 分类统计
                _buildCategoryStats(timeByCategory),
                const SizedBox(height: 24),

                // 时间记录列表
                Text(
                  '时间记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (todayRecords.isEmpty)
                  _buildEmptyState()
                else
                  ...todayRecords.map((record) => _buildRecordCard(record, provider)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRecord(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateHeader() {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

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
            child: Column(
              children: [
                Text(
                  isToday ? '今天' : _formatDate(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _formatDateFull(_selectedDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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

  Widget _buildCategoryStats(Map<TimeCategory, int> timeByCategory) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TimeCategory.values.map((category) {
        final minutes = timeByCategory[category] ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Color(category.color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(category.color).withOpacity(0.3),
            ),
          ),
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
                category.label,
                style: TextStyle(
                  color: Color(category.color),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatMinutes(minutes),
                style: TextStyle(
                  color: Color(category.color),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.access_time,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无时间记录',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角按钮添加记录',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(TimeRecord record, TimeRecordProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: Color(record.category.color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(record.description),
        subtitle: Text(
          '${_formatTime(record.timestamp)} · ${_formatMinutes(record.durationMinutes)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteRecord(record, provider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  String _formatDateFull(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.year}年${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}分钟';
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return mins > 0 ? '${hours}小时${mins}分钟' : '${hours}小时';
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

  void _addRecord(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddRecordSheet(
        selectedDate: _selectedDate,
        onSaved: () {
          context.read<TimeRecordProvider>().loadRecords();
        },
      ),
    );
  }

  void _deleteRecord(TimeRecord record, TimeRecordProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条时间记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRecord(record.id);
              Navigator.pop(context);
            },
            child: Text(
              '删除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// 添加时间记录的底部弹窗
class _AddRecordSheet extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onSaved;

  const _AddRecordSheet({
    required this.selectedDate,
    required this.onSaved,
  });

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  final _descriptionController = TextEditingController();
  TimeCategory _selectedCategory = TimeCategory.mainWork;
  DateTime _timestamp = DateTime.now();
  int _durationMinutes = 30;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '添加时间记录',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // 描述
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '事件描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // 分类选择
            Text(
              '分类',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TimeCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category.label),
                  selected: isSelected,
                  selectedColor: Color(category.color).withOpacity(0.2),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 时间选择
            InkWell(
              onTap: _selectTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '时间',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_timestamp.hour.toString().padLeft(2, '0')}:${_timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    const Icon(Icons.access_time),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 时长选择
            Row(
              children: [
                const Text('时长: '),
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 240,
                    divisions: 47,
                    label: '$_durationMinutes 分钟',
                    onChanged: (value) {
                      setState(() {
                        _durationMinutes = value.round();
                      });
                    },
                  ),
                ),
                Text('$_durationMinutes 分钟'),
              ],
            ),
            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveRecord,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (picked != null) {
      setState(() {
        _timestamp = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveRecord() {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入事件描述')),
      );
      return;
    }

    context.read<TimeRecordProvider>().addRecord(
      timestamp: _timestamp,
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      durationMinutes: _durationMinutes,
    );

    widget.onSaved();
    Navigator.pop(context);
  }
}
