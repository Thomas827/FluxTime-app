import 'package:flutter/material.dart';

/// 快速统计组件
/// 显示今日关键数据概览
class QuickStats extends StatelessWidget {
  final int pendingTasks;
  final int completedToday;
  final int todayMinutes;

  const QuickStats({
    super.key,
    required this.pendingTasks,
    required this.completedToday,
    required this.todayMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.pending_actions,
            label: '待办任务',
            value: '$pendingTasks',
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.check_circle,
            label: '今日完成',
            value: '$completedToday',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.timer,
            label: '今日记录',
            value: _formatMinutes(todayMinutes),
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return mins > 0 ? '${hours}h${mins}m' : '${hours}h';
  }
}
