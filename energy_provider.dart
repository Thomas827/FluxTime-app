import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:fluxtime/models/energy_level.dart';
import 'package:fluxtime/services/database_service.dart';

/// 精力管理状态Provider
class EnergyProvider extends ChangeNotifier {
  List<EnergyLevel> _energyLevels = [];
  bool _isLoading = false;
  String? _error;

  List<EnergyLevel> get energyLevels => _energyLevels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载所有精力记录
  Future<void> loadEnergyLevels() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseService.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'energy_levels',
        orderBy: 'date DESC, time_slot ASC',
      );
      _energyLevels = maps.map((map) => EnergyLevel.fromJson(map)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置某个时间段的精力水平
  Future<void> setEnergyLevel({
    required DateTime date,
    required int timeSlot,
    required int level,
  }) async {
    try {
      final id = const Uuid().v4();
      final energyLevel = EnergyLevel(
        id: id,
        date: date,
        timeSlot: timeSlot,
        level: level,
      );

      final db = await DatabaseService.instance.database;
      
      // 使用 REPLACE 来处理唯一约束冲突
      await db.execute(
        'INSERT OR REPLACE INTO energy_levels (id, date, time_slot, level, created_at) VALUES (?, ?, ?, ?, ?)',
        [id, date.toIso8601String().split('T')[0], timeSlot, level, DateTime.now().toIso8601String()],
      );
      
      // 更新本地列表
      final existingIndex = _energyLevels.indexWhere(
        (e) => e.date.toIso8601String().split('T')[0] == date.toIso8601String().split('T')[0] 
               && e.timeSlot == timeSlot
      );
      
      if (existingIndex != -1) {
        _energyLevels[existingIndex] = energyLevel;
      } else {
        _energyLevels.add(energyLevel);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 批量设置精力水平
  Future<void> setEnergyLevelsBatch({
    required DateTime date,
    required Map<int, int> slotLevels,
  }) async {
    try {
      final db = await DatabaseService.instance.database;
      final batch = db.batch();
      
      slotLevels.forEach((timeSlot, level) {
        final id = const Uuid().v4();
        batch.execute(
          'INSERT OR REPLACE INTO energy_levels (id, date, time_slot, level, created_at) VALUES (?, ?, ?, ?, ?)',
          [id, date.toIso8601String().split('T')[0], timeSlot, level, DateTime.now().toIso8601String()],
        );
      });
      
      await batch.commit();
      await loadEnergyLevels();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 获取指定日期的精力记录
  List<EnergyLevel> getEnergyByDate(DateTime date) {
    return _energyLevels.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }

  /// 获取多日平均精力曲线
  DailyEnergyCurve getAverageCurve(int days) {
    DateTime now = DateTime.now();
    List<DateTime> dates = [];
    
    for (int i = 0; i < days; i++) {
      dates.add(now.subtract(Duration(days: i)));
    }
    
    // 计算每小时的平均精力水平
    List<double> hourlyAverages = List.filled(24, 0.0);
    List<int> counts = List.filled(24, 0);
    
    for (var date in dates) {
      var dayRecords = getEnergyByDate(date);
      
      for (var record in dayRecords) {
        int hour = record.timeSlot ~/ 12; // 每5分钟一个时段，12个时段=1小时
        hourlyAverages[hour] += record.level;
        counts[hour]++;
      }
    }
    
    // 计算平均值
    for (int i = 0; i < 24; i++) {
      if (counts[i] > 0) {
        hourlyAverages[i] = hourlyAverages[i] / counts[i];
      }
    }
    
    return DailyEnergyCurve(date: now, averageLevels: hourlyAverages);
  }

  /// 获取高精力时段
  List<int> getHighEnergyHours(int days) {
    DailyEnergyCurve curve = getAverageCurve(days);
    return curve.highEnergyHours;
  }

  /// 获取今日精力曲线
  List<double> getTodayHourlyLevels() {
    var todayRecords = getEnergyByDate(DateTime.now());
    List<double> hourlyLevels = List.filled(24, 0.0);
    List<int> counts = List.filled(24, 0);
    
    for (var record in todayRecords) {
      int hour = record.timeSlot ~/ 12;
      hourlyLevels[hour] += record.level;
      counts[hour]++;
    }
    
    for (int i = 0; i < 24; i++) {
      if (counts[i] > 0) {
        hourlyLevels[i] = hourlyLevels[i] / counts[i];
      }
    }
    
    return hourlyLevels;
  }

  /// 清除指定日期的精力记录
  Future<void> clearDateRecords(DateTime date) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete(
        'energy_levels',
        where: 'date = ?',
        whereArgs: [date.toIso8601String().split('T')[0]],
      );
      _energyLevels.removeWhere((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
