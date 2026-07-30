import 'package:flutter_test/flutter_test.dart';
import 'package:hopenglish/src/data/app_database.dart';
import 'package:hopenglish/src/data/learning_progress_dao.dart';
import 'package:hopenglish/src/learning/learning_models.dart';
import 'package:hopenglish/src/services/app_settings_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late String databasePath;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databasePath = await AppDatabase.databasePathForTesting();
  });

  tearDown(() async {
    await AppDatabase.closeForTesting();
    await databaseFactory.deleteDatabase(databasePath);
  });

  test('migrates v1 progress without treating it as quiz mastery', () async {
    await databaseFactory.deleteDatabase(databasePath);
    final oldDb = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
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
          await db.execute('''
CREATE TABLE category_progress (
  category_id TEXT PRIMARY KEY,
  last_session_at INTEGER NULL,
  last_exited_at INTEGER NULL
)
''');
          await db.insert('word_progress', {
            'word_key': 'animals:cat',
            'category_id': 'animals',
            'word_id': 'cat',
            'word_name': 'Cat',
            'view_count': 8,
            'play_count': 10,
          });
        },
      ),
    );
    await oldDb.close();

    final migrated = await AppDatabase.getDatabase();
    final rows = await migrated.query(
      'word_progress',
      where: 'word_key = ?',
      whereArgs: ['animals:cat'],
    );

    expect(rows.single['view_count'], 8);
    expect(rows.single['play_count'], 10);
    expect(rows.single['quiz_attempt_count'], 0);
    expect(rows.single['correct_streak'], 0);
  });

  test('persists lesson size and records first-attempt quiz results', () async {
    await AppSettingsService.instance.setLessonWordCount(8);
    expect(await AppSettingsService.instance.getLessonWordCount(), 8);

    final dao = LearningProgressDao();
    await dao.recordQuizResult(
      wordKey: 'animals:dog',
      categoryId: 'animals',
      wordId: 'dog',
      wordName: 'Dog',
      firstAttemptCorrect: true,
      nowMs: 100,
    );
    await dao.recordQuizResult(
      wordKey: 'animals:dog',
      categoryId: 'animals',
      wordId: 'dog',
      wordName: 'Dog',
      firstAttemptCorrect: false,
      nowMs: 200,
    );
    final rows = await dao.getWordProgressByCategory(categoryId: 'animals');
    final dog = rows['animals:dog']!;
    expect(dog['quiz_attempt_count'], 2);
    expect(dog['quiz_correct_count'], 1);
    expect(dog['correct_streak'], 0);
  });

  test('migrates v2 quiz streaks conservatively into v3 stages', () async {
    await databaseFactory.deleteDatabase(databasePath);
    final oldDb = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
CREATE TABLE word_progress (
  word_key TEXT PRIMARY KEY,
  category_id TEXT NOT NULL,
  word_id TEXT NOT NULL,
  word_name TEXT NOT NULL,
  view_count INTEGER NOT NULL DEFAULT 0,
  play_count INTEGER NOT NULL DEFAULT 0,
  quiz_attempt_count INTEGER NOT NULL DEFAULT 0,
  quiz_correct_count INTEGER NOT NULL DEFAULT 0,
  correct_streak INTEGER NOT NULL DEFAULT 0,
  last_seen_at INTEGER NULL,
  last_played_at INTEGER NULL,
  last_quizzed_at INTEGER NULL,
  last_correct_at INTEGER NULL
)
''');
          await db.execute('''
CREATE TABLE category_progress (
  category_id TEXT PRIMARY KEY,
  last_session_at INTEGER NULL,
  last_exited_at INTEGER NULL
)
''');
          await db.execute('''
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
          for (final entry
              in const {'new': 0, 'acquired': 1, 'oldMaster': 3}.entries) {
            await db.insert('word_progress', {
              'word_key': 'animals:${entry.key}',
              'category_id': 'animals',
              'word_id': entry.key,
              'word_name': entry.key,
              'quiz_attempt_count': entry.value == 0 ? 0 : entry.value,
              'quiz_correct_count': entry.value,
              'correct_streak': entry.value,
              'last_quizzed_at': 1000,
            });
          }
        },
      ),
    );
    await oldDb.close();

    final migrated = await AppDatabase.getDatabase();
    final rows = await migrated.query('word_progress');
    final byId = {for (final row in rows) row['word_id']: row};

    expect(byId['new']!['mastery_stage'], MasteryStage.newWord.index);
    expect(byId['acquired']!['mastery_stage'], MasteryStage.acquired.index);
    expect(
      byId['oldMaster']!['mastery_stage'],
      MasteryStage.consolidating.index,
    );
    expect(
      byId['oldMaster']!['next_review_at'],
      1000 + const Duration(days: 3).inMilliseconds,
    );
  });

  test('atomically persists a v2 learning transition', () async {
    final dao = LearningProgressDao();
    final transition = LearningTransition(
      nextStage: MasteryStage.acquired,
      nextReviewLevel: 0,
      nextReviewAtMs: const Duration(days: 1).inMilliseconds,
      shouldRetryInLesson: false,
      stageChanged: true,
    );
    await dao.recordLearningAttempt(
      wordKey: 'animals:fox',
      categoryId: 'animals',
      wordId: 'fox',
      wordName: 'Fox',
      firstAttemptCorrect: true,
      lessonId: 'lesson-1',
      policyVersion: 2,
      transition: transition,
      nowMs: 0,
    );
    final rows = await dao.getWordProgressByCategory(categoryId: 'animals');
    final fox = rows['animals:fox']!;

    expect(fox['mastery_stage'], MasteryStage.acquired.index);
    expect(fox['last_quiz_lesson_id'], 'lesson-1');
    expect(fox['last_quiz_result'], 1);
    expect(fox['last_policy_version'], 2);
  });

  test('falls back to six when a stored lesson size is invalid', () async {
    final dao = LearningProgressDao();
    await dao.setSetting('lesson_word_count', '7');

    expect(await AppSettingsService.instance.getLessonWordCount(), 6);
  });
}
