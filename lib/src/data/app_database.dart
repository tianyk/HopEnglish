import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// 应用本地数据库（SQLite + sqflite）
///
/// - 数据文件落在应用私有目录中（iOS/Android 沙盒），由 sqflite 管理。
/// - 表结构变更通过 version + onUpgrade 管理（见 docs/learning_progress_vnext.md）。
class AppDatabase {
  /// 数据库文件名（SQLite 文件）。
  static const String _databaseFileName = 'hopenglish.sqlite';

  /// 数据库结构版本号。
  ///
  /// 规则：
  /// - 每次“表结构变更”必须递增
  /// - 并在 [_onUpgrade] 中写增量迁移逻辑
  static const int _schemaVersion = 1;

  /// 全局单例连接（进程内缓存）。
  static Database? _database;

  AppDatabase._();

  /// 获取数据库连接。
  ///
  /// - 首次调用会打开 SQLite 文件，并在首次安装时触发建表（onCreate）
  /// - 后续调用复用同一个连接，避免重复 openDatabase 的开销
  static Future<Database> getDatabase() async {
    final cached = _database;
    if (cached != null) return cached;

    // sqflite 统一放在系统数据库目录下（iOS/Android 沙盒内的私有目录）。
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseFileName);

    final database = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: (db, version) async => _onCreate(db),
      onUpgrade: (db, from, to) async => _onUpgrade(db, from, to),
      onConfigure: (db) async {
        // 预留：如未来增加外键约束可开启
        // await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    _database = database;
    return database;
  }

  /// 轻量探测数据库连接是否可用（建议在启动时调用）。
  ///
  /// 目的：提前触发 openDatabase / 建表，避免首次进入学习页时承担“第一次开库 + 建表”的延迟。
  static Future<void> ping() async {
    final db = await getDatabase();
    await db.rawQuery('SELECT 1');
  }

  static Future<void> _onCreate(Database db) async {
    // 单词学习进度表（学习项粒度）：
    // - word_key = "$categoryId:$wordId"（稳定主键）
    // - view_count/play_count 用于覆盖与兴趣信号
    // - last_seen_at/last_played_at 用于时间分档（久别重启/复习）
    await db.execute('''
CREATE TABLE word_progress (
  word_key TEXT PRIMARY KEY,
  category_id TEXT NOT NULL,
  word_id TEXT NOT NULL,
  word_name TEXT NOT NULL,
  view_count INTEGER NOT NULL DEFAULT 0,
  play_count INTEGER NOT NULL DEFAULT 0,
  last_seen_at INTEGER NULL,
  last_played_at INTEGER NULL
)
''');
    // 主题索引：按主题批量读取/统计时更快。
    await db.execute('CREATE INDEX idx_word_progress_category_id ON word_progress(category_id)');
    // 时间索引：后续按 last_seen_at 做 Overdue 桶筛选时更快。
    await db.execute('CREATE INDEX idx_word_progress_last_seen_at ON word_progress(last_seen_at)');

    // 主题学习会话表（主题粒度）：
    // - last_session_at 用于判断日常/复习加强/久别重启
    // - last_exited_at 主要用于调试/统计（可选字段）
    await db.execute('''
CREATE TABLE category_progress (
  category_id TEXT PRIMARY KEY,
  last_session_at INTEGER NULL,
  last_exited_at INTEGER NULL
)
''');
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    // v1 -> vN: 在这里做增量迁移（add column / create table / backfill 等）
    // 迁移策略与模板见 docs/learning_progress_vnext.md
  }
}
