import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库服务
/// 管理SQLite数据库的创建和操作
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fluxtime.db');
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// 创建数据库表
  Future<void> _createDB(Database db, int version) async {
    // 任务表
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        goal TEXT,
        due_date TEXT,
        estimated_minutes INTEGER DEFAULT 60,
        urgent INTEGER DEFAULT 5,
        cost INTEGER DEFAULT 5,
        effort INTEGER DEFAULT 5,
        value INTEGER DEFAULT 5,
        impact INTEGER DEFAULT 5,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        completed_at TEXT
      )
    ''');

    // 时间记录表
    await db.execute('''
      CREATE TABLE time_records (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        description TEXT NOT NULL,
        category INTEGER NOT NULL,
        duration_minutes INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 精力水平表
    await db.execute('''
      CREATE TABLE energy_levels (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        time_slot INTEGER NOT NULL,
        level INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(date, time_slot)
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks(due_date)');
    await db.execute('CREATE INDEX idx_tasks_is_completed ON tasks(is_completed)');
    await db.execute('CREATE INDEX idx_time_records_timestamp ON time_records(timestamp)');
    await db.execute('CREATE INDEX idx_energy_levels_date ON energy_levels(date)');
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
