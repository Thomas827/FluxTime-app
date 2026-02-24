import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluxtime/providers/task_provider.dart';
import 'package:fluxtime/providers/time_record_provider.dart';
import 'package:fluxtime/providers/energy_provider.dart';
import 'package:fluxtime/screens/todo_screen.dart';
import 'package:fluxtime/screens/time_record_screen.dart';
import 'package:fluxtime/screens/energy_screen.dart';
import 'package:fluxtime/screens/stats_screen.dart';
import 'package:fluxtime/widgets/daily_recommendation.dart';
import 'package:fluxtime/widgets/quick_stats.dart';

/// 主页面 - 包含底部导航和5个核心页面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const _HomePage(),
    const TodoScreen(),
    const TimeRecordScreen(),
    const EnergyScreen(),
    const StatsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<TaskProvider>().loadTasks();
    await context.read<TimeRecordProvider>().loadRecords();
    await context.read<EnergyProvider>().loadEnergyLevels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: '时间',
          ),
          NavigationDestination(
            icon: Icon(Icons.battery_charging_full_outlined),
            selectedIcon: Icon(Icons.battery_charging_full),
            label: '精力',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '统计',
          ),
        ],
      ),
    );
  }
}

/// 首页内容 - 每日推荐
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FluxTime'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TaskProvider>().loadTasks();
              context.read<EnergyProvider>().loadEnergyLevels();
            },
          ),
        ],
      ),
      body: Consumer3<TaskProvider, EnergyProvider, TimeRecordProvider>(
        builder: (context, taskProvider, energyProvider, timeProvider, child) {
          if (taskProvider.isLoading || energyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await taskProvider.loadTasks();
              await energyProvider.loadEnergyLevels();
              await timeProvider.loadRecords();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期和问候
                  _buildGreeting(),
                  const SizedBox(height: 24),
                  
                  // 快速统计
                  QuickStats(
                    pendingTasks: taskProvider.pendingTasks.length,
                    completedToday: taskProvider.completedTasks
                        .where((t) => t.completedAt != null &&
                            _isToday(t.completedAt!))
                        .length,
                    todayMinutes: timeProvider.getTodayTotalMinutes(),
                  ),
                  const SizedBox(height: 24),
                  
                  // 每日推荐
                  DailyRecommendation(
                    tasks: taskProvider.pendingTasks,
                    energyCurve: energyProvider.getAverageCurve(7),
                  ),
                  const SizedBox(height: 24),
                  
                  // 高优先级任务
                  _buildHighPrioritySection(context, taskProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = '早上好';
    } else if (hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _getDateString(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  String _getDateString() {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${now.year}年${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _buildHighPrioritySection(BuildContext context, TaskProvider taskProvider) {
    final highPriorityTasks = taskProvider.getHighPriorityTasks();
    
    if (highPriorityTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.priority_high,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              '高优先级任务',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...highPriorityTasks.take(3).map((task) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: Color(task.priorityColor),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(task.name),
            subtitle: Text('UCEVI评分: ${task.uceviScore}'),
            trailing: Text(
              task.priorityLevel,
              style: TextStyle(
                color: Color(task.priorityColor),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )),
      ],
    );
  }
}
