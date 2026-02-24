/// 时间记录数据模型
/// 用于记录用户的时间使用情况
class TimeRecord {
  final String id;
  DateTime timestamp;
  String description;
  TimeCategory category;
  int durationMinutes;
  DateTime createdAt;

  TimeRecord({
    required this.id,
    required this.timestamp,
    required this.description,
    required this.category,
    this.durationMinutes = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从JSON创建时间记录
  factory TimeRecord.fromJson(Map<String, dynamic> json) {
    return TimeRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String,
      category: TimeCategory.values[json['category'] as int],
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'category': category.index,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 时间分类枚举
enum TimeCategory {
  mainWork('主要工作', 0xFF3B82F6),
  dailyLife('日常生活', 0xFF10B981),
  selfImprovement('自我提升', 0xFF8B5CF6),
  health('健康', 0xFFEF4444),
  relationships('人际关系', 0xFFF59E0B),
  rest('休息', 0xFF6B7280);

  final String label;
  final int color;

  const TimeCategory(this.label, this.color);
}
