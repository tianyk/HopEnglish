import 'package:sqflite/sqflite.dart';
import 'package:hopenglish/src/data/app_database.dart';
import 'package:hopenglish/src/learning/learning_models.dart';

/// 学习进度 DAO（SQLite + sqflite）
///
/// 说明：
/// - 表名/字段名使用 snake_case（与技术文档一致）
/// - 写入采用"insertOrIgnore + 原子 update"两步：
///   - 先确保行存在（避免首次写入更新不到任何行）
///   - 再用 SQL 语句原子自增计数（避免 read-modify-write 竞争）
class LearningProgressDao {
  Future<Database> _getDb() => AppDatabase.getDatabase();

  /// 获取主题上次进入学习页的时间（epoch ms）。
  Future<int?> getCategoryLastSessionAt({required String categoryId}) async {
    final db = await _getDb();
    final rows = await db.query(
      'category_progress',
      columns: ['last_session_at'],
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['last_session_at'] as int?;
  }

  /// 获取主题下所有学习项的进度数据（按 wordKey 映射）。
  ///
  /// 用途：后续自适应排序（Overdue/Warm/Favorite 分桶）需要批量读取该主题的历史数据。
  Future<Map<String, Map<String, Object?>>> getWordProgressByCategory(
      {required String categoryId}) async {
    final db = await _getDb();
    final rows = await db.query(
      'word_progress',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return {for (final row in rows) row['word_key'] as String: row};
  }

  Future<String?> getSetting(String key) async {
    final db = await _getDb();
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _getDb();
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 进入主题学习页时更新主题会话锚点（last_session_at）。
  Future<void> touchCategorySession(
      {required String categoryId, required int nowMs}) async {
    final db = await _getDb();
    await _upsertCategoryProgress(db, categoryId);
    await db.rawUpdate(
      'UPDATE category_progress SET last_session_at = ? WHERE category_id = ?',
      [nowMs, categoryId],
    );
  }

  /// 离开主题学习页时更新 last_exited_at（可选字段，便于调试/统计/会话边界更稳）。
  Future<void> saveCategoryExitedAt(
      {required String categoryId, required int nowMs}) async {
    final db = await _getDb();
    await _upsertCategoryProgress(db, categoryId);
    await db.rawUpdate(
      'UPDATE category_progress SET last_exited_at = ? WHERE category_id = ?',
      [nowMs, categoryId],
    );
  }

  /// viewCount +1，并更新 last_seen_at。
  Future<void> incrementView({
    required String wordKey,
    required String categoryId,
    required String wordId,
    required String wordName,
    required int nowMs,
  }) async {
    final db = await _getDb();
    await _upsertWordProgress(db,
        wordKey: wordKey,
        categoryId: categoryId,
        wordId: wordId,
        wordName: wordName);
    await db.rawUpdate(
      'UPDATE word_progress SET view_count = view_count + 1, last_seen_at = ? WHERE word_key = ?',
      [nowMs, wordKey],
    );
  }

  /// playCount +1，并更新 last_played_at。
  ///
  /// 注意：连点合并窗口不在 DAO 做，而在 service 层做（DAO 保持"按请求忠实写入"）。
  Future<void> incrementPlay({
    required String wordKey,
    required String categoryId,
    required String wordId,
    required String wordName,
    required int nowMs,
  }) async {
    final db = await _getDb();
    await _upsertWordProgress(db,
        wordKey: wordKey,
        categoryId: categoryId,
        wordId: wordId,
        wordName: wordName);
    await db.rawUpdate(
      'UPDATE word_progress SET play_count = play_count + 1, last_played_at = ? WHERE word_key = ?',
      [nowMs, wordKey],
    );
  }

  Future<void> recordQuizResult({
    required String wordKey,
    required String categoryId,
    required String wordId,
    required String wordName,
    required bool firstAttemptCorrect,
    required int nowMs,
  }) async {
    final db = await _getDb();
    await _upsertWordProgress(
      db,
      wordKey: wordKey,
      categoryId: categoryId,
      wordId: wordId,
      wordName: wordName,
    );
    if (firstAttemptCorrect) {
      await db.rawUpdate(
        '''
UPDATE word_progress
SET quiz_attempt_count = quiz_attempt_count + 1,
    quiz_correct_count = quiz_correct_count + 1,
    correct_streak = correct_streak + 1,
    last_quizzed_at = ?,
    last_correct_at = ?
WHERE word_key = ?
''',
        [nowMs, nowMs, wordKey],
      );
    } else {
      await db.rawUpdate(
        '''
UPDATE word_progress
SET quiz_attempt_count = quiz_attempt_count + 1,
    correct_streak = 0,
    last_quizzed_at = ?
WHERE word_key = ?
''',
        [nowMs, wordKey],
      );
    }
  }

  Future<void> recordLearningAttempt({
    required String wordKey,
    required String categoryId,
    required String wordId,
    required String wordName,
    required bool firstAttemptCorrect,
    required String lessonId,
    required int policyVersion,
    required LearningTransition transition,
    required int nowMs,
  }) async {
    final db = await _getDb();
    await db.transaction((txn) async {
      await _upsertWordProgress(
        txn,
        wordKey: wordKey,
        categoryId: categoryId,
        wordId: wordId,
        wordName: wordName,
      );
      await txn.rawUpdate(
        '''
UPDATE word_progress
SET quiz_attempt_count = quiz_attempt_count + 1,
    quiz_correct_count = quiz_correct_count + ?,
    correct_streak = CASE
      WHEN ? = 1 THEN correct_streak + 1
      ELSE 0
    END,
    last_quizzed_at = ?,
    last_correct_at = CASE
      WHEN ? = 1 THEN ?
      ELSE last_correct_at
    END,
    mastery_stage = ?,
    review_level = ?,
    next_review_at = ?,
    last_quiz_lesson_id = ?,
    last_quiz_result = ?,
    last_policy_version = ?
WHERE word_key = ?
''',
        [
          firstAttemptCorrect ? 1 : 0,
          firstAttemptCorrect ? 1 : 0,
          nowMs,
          firstAttemptCorrect ? 1 : 0,
          nowMs,
          transition.nextStage.index,
          transition.nextReviewLevel,
          transition.nextReviewAtMs,
          lessonId,
          firstAttemptCorrect ? 1 : 0,
          policyVersion,
          wordKey,
        ],
      );
    });
  }

  /// 确保 word_progress 行存在（首次遇到该词时插入，已存在则忽略）。
  Future<void> _upsertWordProgress(
    DatabaseExecutor db, {
    required String wordKey,
    required String categoryId,
    required String wordId,
    required String wordName,
  }) async {
    await db.insert(
      'word_progress',
      {
        'word_key': wordKey,
        'category_id': categoryId,
        'word_id': wordId,
        'word_name': wordName
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// 确保 category_progress 行存在。
  Future<void> _upsertCategoryProgress(Database db, String categoryId) async {
    await db.insert(
      'category_progress',
      {'category_id': categoryId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
