import 'package:fluxtime/models/task.dart';
import 'package:fluxtime/models/energy_level.dart';

/// UCEVI评分服务
/// 提供任务评分计算和推荐功能
class UceviService {
  static final UceviService instance = UceviService._init();
  UceviService._init();

  /// 计算单个任务的UCEVI评分
  double calculateScore(Task task) {
    return task.uceviScore;
  }

  /// 批量计算并排序任务
  List<Task> sortTasksByScore(List<Task> tasks) {
    List<Task> sortedTasks = List.from(tasks);
    sortedTasks.sort((a, b) => b.uceviScore.compareTo(a.uceviScore));
    return sortedTasks;
  }

  /// 获取高优先级任务（评分>=6）
  List<Task> getHighPriorityTasks(List<Task> tasks) {
    return tasks.where((t) => t.uceviScore >= 6 && !t.isCompleted).toList();
  }

  /// 根据精力曲线推荐任务
  /// 返回推荐的任务列表和对应的时间段
  List<TaskRecommendation> recommendTasks(
    List<Task> tasks,
    DailyEnergyCurve energyCurve,
  ) {
    List<Task> pendingTasks = tasks.where((t) => !t.isCompleted).toList();
    List<Task> sortedTasks = sortTasksByScore(pendingTasks);
    List<int> highEnergyHours = energyCurve.highEnergyHours;
    
    List<TaskRecommendation> recommendations = [];
    
    for (int i = 0; i < sortedTasks.length && i < 5; i++) {
      Task task = sortedTasks[i];
      
      // 高评分任务匹配高精力时段
      bool preferHighEnergy = task.uceviScore >= 6;
      
      String recommendedTime;
      if (preferHighEnergy && highEnergyHours.isNotEmpty) {
        int hour = highEnergyHours[i % highEnergyHours.length];
        recommendedTime = '${hour.toString().padLeft(2, '0')}:00';
      } else {
        // 低精力时段适合低评分任务
        recommendedTime = '灵活安排';
      }
      
      recommendations.add(TaskRecommendation(
        task: task,
        recommendedTime: recommendedTime,
        reason: _getRecommendationReason(task, preferHighEnergy),
      ));
    }
    
    return recommendations;
  }

  /// 获取推荐原因
  String _getRecommendationReason(Task task, bool preferHighEnergy) {
    if (task.uceviScore >= 8) {
      return '极高优先级，建议在高精力时段完成';
    } else if (task.uceviScore >= 6) {
      return '高优先级任务，推荐精力充沛时处理';
    } else if (task.uceviScore >= 4) {
      return '中等优先级，可在常规时段完成';
    } else {
      return '低优先级，可在碎片时间处理';
    }
  }

  /// 计算今日任务完成率
  double calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    int completed = tasks.where((t) => t.isCompleted).length;
    return completed / tasks.length;
  }

  /// 获取任务统计摘要
  TaskSummary getTaskSummary(List<Task> tasks) {
    List<Task> pending = tasks.where((t) => !t.isCompleted).toList();
    List<Task> completed = tasks.where((t) => t.isCompleted).toList();
    
    double avgScore = pending.isEmpty 
        ? 0 
        : pending.map((t) => t.uceviScore).reduce((a, b) => a + b) / pending.length;
    
    int highPriority = pending.where((t) => t.uceviScore >= 6).length;
    
    return TaskSummary(
      totalTasks: tasks.length,
      pendingTasks: pending.length,
      completedTasks: completed.length,
      averageScore: double.parse(avgScore.toStringAsFixed(2)),
      highPriorityCount: highPriority,
    );
  }
}

/// 任务推荐结果
class TaskRecommendation {
  final Task task;
  final String recommendedTime;
  final String reason;

  TaskRecommendation({
    required this.task,
    required this.recommendedTime,
    required this.reason,
  });
}

/// 任务统计摘要
class TaskSummary {
  final int totalTasks;
  final int pendingTasks;
  final int completedTasks;
  final double averageScore;
  final int highPriorityCount;

  TaskSummary({
    required this.totalTasks,
    required this.pendingTasks,
    required this.completedTasks,
    required this.averageScore,
    required this.highPriorityCount,
  });
}
