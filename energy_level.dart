/// 精力水平数据模型
/// 用于记录用户在不同时间段的精力状态
class EnergyLevel {
  final String id;
  DateTime date;
  int timeSlot;      // 时间段索引 (0-287, 每5分钟一个时段, 24小时=288个时段)
  int level;         // 精力水平 0=低, 1=高
  DateTime createdAt;

  EnergyLevel({
    required this.id,
    required this.date,
    required this.timeSlot,
    required this.level,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 获取时间段对应的时间字符串
  String get timeString {
    int totalMinutes = timeSlot * 5;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// 从JSON创建精力记录
  factory EnergyLevel.fromJson(Map<String, dynamic> json) {
    return EnergyLevel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      timeSlot: json['time_slot'] as int,
      level: json['level'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'time_slot': timeSlot,
      'level': level,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 每日精力曲线数据
class DailyEnergyCurve {
  final DateTime date;
  final List<double> averageLevels;  // 每小时的平均精力水平 (0-1)

  DailyEnergyCurve({
    required this.date,
    required this.averageLevels,
  });

  /// 获取高精力时段
  List<int> get highEnergyHours {
    List<int> hours = [];
    for (int i = 0; i < averageLevels.length; i++) {
      if (averageLevels[i] >= 0.6) {
        hours.add(i);
      }
    }
    return hours;
  }

  /// 获取推荐工作时段描述
  String get recommendedPeriods {
    if (highEnergyHours.isEmpty) return '暂无数据';
    
    List<String> periods = [];
    int? startHour;
    
    for (int i = 0; i <= averageLevels.length; i++) {
      bool isHigh = i < averageLevels.length && averageLevels[i] >= 0.6;
      
      if (isHigh && startHour == null) {
        startHour = i;
      } else if (!isHigh && startHour != null) {
        periods.add('${startHour.toString().padLeft(2, '0')}:00-${i.toString().padLeft(2, '0')}:00');
        startHour = null;
      }
    }
    
    return periods.isEmpty ? '暂无高精力时段' : periods.join(', ');
  }
}
