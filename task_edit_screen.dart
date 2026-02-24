import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluxtime/models/task.dart';
import 'package:fluxtime/providers/task_provider.dart';

/// 任务编辑页面
class TaskEditScreen extends StatefulWidget {
  final Task? task;

  const TaskEditScreen({super.key, this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  
  DateTime? _dueDate;
  int _estimatedMinutes = 60;
  int _urgent = 5;
  int _cost = 5;
  int _effort = 5;
  int _value = 5;
  int _impact = 5;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? '');
    _goalController = TextEditingController(text: widget.task?.goal ?? '');
    _dueDate = widget.task?.dueDate;
    _estimatedMinutes = widget.task?.estimatedMinutes ?? 60;
    _urgent = widget.task?.urgent ?? 5;
    _cost = widget.task?.cost ?? 5;
    _effort = widget.task?.effort ?? 5;
    _value = widget.task?.value ?? 5;
    _impact = widget.task?.impact ?? 5;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑任务' : '新建任务'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 任务名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '任务名称 *',
                hintText: '输入任务名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入任务名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 所属目标
            TextFormField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: '所属目标',
                hintText: '可选，输入目标名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 截止日期
            InkWell(
              onTap: _selectDueDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '截止日期',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dueDate != null
                          ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                          : '选择日期',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 预估耗时
            _buildNumberInput(
              label: '预估耗时（分钟）',
              value: _estimatedMinutes,
              min: 5,
              max: 480,
              step: 15,
              onChanged: (value) => setState(() => _estimatedMinutes = value),
            ),
            const SizedBox(height: 24),

            // UCEVI评分区域
            Text(
              'UCEVI评分指标',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '拖动滑块设置各项指标（1-10分）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            _buildSlider(
              label: 'U - 紧急度 (Urgent)',
              value: _urgent,
              color: Colors.red,
              description: '任务的时间紧迫程度',
              onChanged: (value) => setState(() => _urgent = value),
            ),
            _buildSlider(
              label: 'C - 花费 (Cost)',
              value: _cost,
              color: Colors.orange,
              description: '完成任务需要的资源消耗',
              onChanged: (value) => setState(() => _cost = value),
            ),
            _buildSlider(
              label: 'E - 努力 (Effort)',
              value: _effort,
              color: Colors.yellow,
              description: '完成任务需要的工作量',
              onChanged: (value) => setState(() => _effort = value),
            ),
            _buildSlider(
              label: 'V - 价值 (Value)',
              value: _value,
              color: Colors.green,
              description: '任务带来的价值回报',
              onChanged: (value) => setState(() => _value = value),
            ),
            _buildSlider(
              label: 'I - 影响 (Impact)',
              value: _impact,
              color: Colors.blue,
              description: '任务对目标的影响程度',
              onChanged: (value) => setState(() => _impact = value),
            ),

            const SizedBox(height: 24),

            // UCEVI评分预览
            _buildScorePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required int value,
    required Color color,
    required String description,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Slider(
              value: value.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: color,
              onChanged: (v) => onChanged(v.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePreview() {
    double score = (_urgent * 0.25 +
        _cost * 0.15 +
        _effort * 0.15 +
        _value * 0.25 +
        _impact * 0.20) *
        10;

    String level;
    Color levelColor;
    if (score >= 8) {
      level = '极高优先级';
      levelColor = const Color(0xFFEF4444);
    } else if (score >= 6) {
      level = '高优先级';
      levelColor = const Color(0xFFF59E0B);
    } else if (score >= 4) {
      level = '中等优先级';
      levelColor = const Color(0xFF10B981);
    } else {
      level = '低优先级';
      levelColor = const Color(0xFF6B7280);
    }

    return Card(
      color: levelColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UCEVI综合评分',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    score.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: levelColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                level,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = context.read<TaskProvider>();

    if (isEditing) {
      final updatedTask = widget.task!.copyWith(
        name: _nameController.text.trim(),
        goal: _goalController.text.trim().isEmpty ? null : _goalController.text.trim(),
        dueDate: _dueDate,
        estimatedMinutes: _estimatedMinutes,
        urgent: _urgent,
        cost: _cost,
        effort: _effort,
        value: _value,
        impact: _impact,
      );
      taskProvider.updateTask(updatedTask);
    } else {
      taskProvider.addTask(
        name: _nameController.text.trim(),
        goal: _goalController.text.trim().isEmpty ? null : _goalController.text.trim(),
        dueDate: _dueDate,
        estimatedMinutes: _estimatedMinutes,
        urgent: _urgent,
        cost: _cost,
        effort: _effort,
        value: _value,
        impact: _impact,
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? '任务已更新' : '任务已创建'),
      ),
    );
  }
}
