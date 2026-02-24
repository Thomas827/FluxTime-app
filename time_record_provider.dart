import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:fluxtime/models/time_record.dart';
import 'package:fluxtime/services/database_service.dart';

/// 时间记录状态管理Provider
class TimeRecordProvider extends ChangeNotifier {
  List<TimeRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  List<TimeRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载所有时间记录
  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseService.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'time_records',
        orderBy: 'timestamp DESC',
      );
      _records = maps.map((map) => TimeRecord.fromJson(map)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加时间记录
  Future<void> addRecord({
    required DateTime timestamp,
    required String description,
    required TimeCategory category,
    int durationMinutes = 0,
  }) async {
    try {
      final record = TimeRecord(
        id: const Uuid().v4(),
        timestamp: timestamp,
        description: description,
        category: category,
        durationMinutes: durationMinutes,
      );

      final db = await DatabaseService.instance.database;
      await db.insert('time_records', record.toJson());
      _records.insert(0, record);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新时间记录
  Future<void> updateRecord(TimeRecord record) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.update(
        'time_records',
        record.toJson(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
      
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 删除时间记录
  Future<void> deleteRecord(String recordId) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete(
        'time_records',
        where: 'id = ?',
        whereArgs: [recordId],
      );
      _records.removeWhere((r) => r.id == recordId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 获取指定日期的记录
  List<TimeRecord> getRecordsByDate(DateTime date) {
    return _records.where((r) {
      return r.timestamp.year == date.year &&
          r.timestamp.month == date.month &&
          r.timestamp.day == date.day;
    }).toList();
  }

  /// 获取指定日期范围的记录
  List<TimeRecord> getRecordsByDateRange(DateTime start, DateTime end) {
    return _records.where((r) {
      return r.timestamp.isAfter(start) && r.timestamp.isBefore(end);
    }).toList();
  }

  /// 按分类统计时间
  Map<TimeCategory, int> getTimeByCategory({DateTime? date}) {
    List<TimeRecord> filtered = date != null 
        ? getRecordsByDate(date) 
        : _records;
    
    Map<TimeCategory, int> result = {};
    for (var category in TimeCategory.values) {
      int total = filtered
          .where((r) => r.category == category)
          .fold(0, (sum, r) => sum + r.durationMinutes);
      result[category] = total;
    }
    return result;
  }

  /// 获取今日总时间
  int getTodayTotalMinutes() {
    final today = DateTime.now();
    return getRecordsByDate(today)
        .fold(0, (sum, r) => sum + r.durationMinutes);
  }

  /// 获取分类统计百分比
  Map<TimeCategory, double> getCategoryPercentages({DateTime? date}) {
    Map<TimeCategory, int> timeByCategory = getTimeByCategory(date: date);
    int total = timeByCategory.values.fold(0, (sum, v) => sum + v);
    
    if (total == 0) return {};
    
    Map<TimeCategory, double> percentages = {};
    timeByCategory.forEach((category, minutes) {
      percentages[category] = minutes / total;
    });
    return percentages;
  }
}
