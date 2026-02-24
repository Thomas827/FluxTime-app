import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:fluxtime/models/task.dart';
import 'package:fluxtime/services/database_service.dart';

/// 任务状态管理Provider
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  List<Task> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载所有任务
  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = await DatabaseService.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        orderBy: 'created_at DESC',
      );
      _tasks = maps.map((map) => Task.fromJson(map)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加新任务
  Future<void> addTask({
    required String name,
    String? goal,
    DateTime? dueDate,
    int estimatedMinutes = 60,
    int urgent = 5,
    int cost = 5,
    int effort = 5,
    int value = 5,
    int impact = 5,
  }) async {
    try {
      final task = Task(
        id: const Uuid().v4(),
        name: name,
        goal: goal,
        dueDate: dueDate,
        estimatedMinutes: estimatedMinutes,
        urgent: urgent,
        cost: cost,
        effort: effort,
        value: value,
        impact: impact,
      );

      final db = await DatabaseService.instance.database;
      await db.insert('tasks', task.toJson());
      _tasks.insert(0, task);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新任务
  Future<void> updateTask(Task task) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.update(
        'tasks',
        task.toJson(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 标记任务完成
  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    await updateTask(updatedTask);
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 按UCEVI评分排序获取任务
  List<Task> getTasksSortedByScore() {
    List<Task> sorted = List.from(pendingTasks);
    sorted.sort((a, b) => b.uceviScore.compareTo(a.uceviScore));
    return sorted;
  }

  /// 获取高优先级任务
  List<Task> getHighPriorityTasks() {
    return pendingTasks.where((t) => t.uceviScore >= 6).toList();
  }

  /// 按目标筛选任务
  List<Task> getTasksByGoal(String? goal) {
    if (goal == null || goal.isEmpty) return pendingTasks;
    return pendingTasks.where((t) => t.goal == goal).toList();
  }

  /// 获取所有目标列表
  List<String> getAllGoals() {
    return _tasks
        .where((t) => t.goal != null && t.goal!.isNotEmpty)
        .map((t) => t.goal!)
        .toSet()
        .toList();
  }
}
