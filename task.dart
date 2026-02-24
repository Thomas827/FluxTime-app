/// 任务数据模型
/// 包含任务的所有属性和UCEVI评分计算
class Task {
  final String id;
  String name;
  String? goal;
  DateTime? dueDate;
  int estimatedMinutes;
  int urgent;      // 紧急度 1-10
  int cost;        // 花费 1-10
  int effort;      // 努力 1-10
  int value;       // 价值 1-10
  int impact;      // 影响 1-10
  bool isCompleted;
  DateTime createdAt;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.name,
    this.goal,
    this.dueDate,
    this.estimatedMinutes = 60,
    this.urgent = 5,
    this.cost = 5,
    this.effort = 5,
    this.value = 5,
    this.impact = 5,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// UCEVI综合评分计算公式
  /// UCEVI = (Urgent × 0.25 + Cost × 0.15 + Effort × 0.15 + Value × 0.25 + Impact × 0.20) × 10
  double get uceviScore {
    double score = (urgent * 0.25 +
        cost * 0.15 +
        effort * 0.15 +
        value * 0.25 +
        impact * 0.20) * 10;
    return double.parse(score.toStringAsFixed(2));
  }

  /// 获取优先级等级
  String get priorityLevel {
    if (uceviScore >= 8) return '极高';
    if (uceviScore >= 6) return '高';
    if (uceviScore >= 4) return '中';
    return '低';
  }

  /// 获取优先级颜色
  int get priorityColor {
    if (uceviScore >= 8) return 0xFFEF4444; // 红色
    if (uceviScore >= 6) return 0xFFF59E0B; // 橙色
    if (uceviScore >= 4) return 0xFF10B981; // 绿色
    return 0xFF6B7280; // 灰色
  }

  /// 从JSON创建任务
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      goal: json['goal'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      estimatedMinutes: json['estimated_minutes'] as int? ?? 60,
      urgent: json['urgent'] as int? ?? 5,
      cost: json['cost'] as int? ?? 5,
      effort: json['effort'] as int? ?? 5,
      value: json['value'] as int? ?? 5,
      impact: json['impact'] as int? ?? 5,
      isCompleted: json['is_completed'] == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'goal': goal,
      'due_date': dueDate?.toIso8601String(),
      'estimated_minutes': estimatedMinutes,
      'urgent': urgent,
      'cost': cost,
      'effort': effort,
      'value': value,
      'impact': impact,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// 复制并修改任务
  Task copyWith({
    String? id,
    String? name,
    String? goal,
    DateTime? dueDate,
    int? estimatedMinutes,
    int? urgent,
    int? cost,
    int? effort,
    int? value,
    int? impact,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      dueDate: dueDate ?? this.dueDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      urgent: urgent ?? this.urgent,
      cost: cost ?? this.cost,
      effort: effort ?? this.effort,
      value: value ?? this.value,
      impact: impact ?? this.impact,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
