import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluxtime/providers/task_provider.dart';
import 'package:fluxtime/models/task.dart';
import 'package:fluxtime/screens/task_edit_screen.dart';

/// 待办管理页面
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'score'; // score, date, name

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待办管理'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'score',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('按评分排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('按日期排序'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('按名称排序'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '待完成'),
            Tab(text: '已完成'),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(context, taskProvider.pendingTasks, taskProvider),
              _buildTaskList(context, taskProvider.completedTasks, taskProvider, isCompleted: true),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    List<Task> tasks,
    TaskProvider taskProvider, {
    bool isCompleted = false,
  }) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_outline : Icons.list_alt,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted ? '暂无已完成任务' : '暂无待办任务',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            if (!isCompleted) ...[
              const SizedBox(height: 8),
              Text(
                '点击右下角按钮添加新任务',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    }

    // 排序
    List<Task> sortedTasks = List.from(tasks);
    switch (_sortBy) {
      case 'score':
        sortedTasks.sort((a, b) => b.uceviScore.compareTo(a.uceviScore));
        break;
      case 'date':
        sortedTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'name':
        sortedTasks.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        return _buildTaskCard(context, task, taskProvider);
      },
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editTask(context, task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 完成状态
                  GestureDetector(
                    onTap: () => taskProvider.toggleTaskCompletion(task),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isCompleted
                              ? Colors.green
                              : Theme.of(context).colorScheme.outline,
                          width: 2,
                        ),
                        color: task.isCompleted ? Colors.green : null,
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 任务名称
                  Expanded(
                    child: Text(
                      task.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? Theme.of(context).colorScheme.outline
                                : null,
                          ),
                    ),
                  ),
                  
                  // UCEVI评分
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(task.priorityColor).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.uceviScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(task.priorityColor),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (!task.isCompleted) ...[
                const SizedBox(height: 12),
                
                // 任务详情
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (task.goal != null && task.goal!.isNotEmpty)
                      _buildChip(
                        Icons.flag,
                        task.goal!,
                        Theme.of(context).colorScheme.primary,
                      ),
                    if (task.dueDate != null)
                      _buildChip(
                        Icons.calendar_today,
                        _formatDate(task.dueDate!),
                        Colors.orange,
                      ),
                    _buildChip(
                      Icons.timer,
                      '${task.estimatedMinutes}分钟',
                      Colors.blue,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // UCEVI指标
                Row(
                  children: [
                    _buildIndicator('U', task.urgent, Colors.red),
                    _buildIndicator('C', task.cost, Colors.orange),
                    _buildIndicator('E', task.effort, Colors.yellow),
                    _buildIndicator('V', task.value, Colors.green),
                    _buildIndicator('I', task.impact, Colors.blue),
                  ],
                ),
              ],
              
              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _editTask(context, task),
                    child: const Text('编辑'),
                  ),
                  TextButton(
                    onPressed: () => _deleteTask(context, task, taskProvider),
                    child: Text(
                      '删除',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _addTask(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskEditScreen(),
      ),
    );
  }

  void _editTask(BuildContext context, Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(task: task),
      ),
    );
  }

  void _deleteTask(BuildContext context, Task task, TaskProvider taskProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除任务"${task.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              taskProvider.deleteTask(task.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('任务已删除')),
              );
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
