import 'dart:math';

import 'package:hopenglish/src/data/learning_progress_dao.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/lesson_plan.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/models/word_bucket.dart';

class LessonSessionService {
  static final LessonSessionService _instance = LessonSessionService._();
  static LessonSessionService get instance => _instance;

  static const Duration _reviewDueAfter = Duration(days: 7);

  final LearningProgressDao _dao;
  final Random _random;

  LessonSessionService._({
    LearningProgressDao? dao,
    Random? random,
  })  : _dao = dao ?? LearningProgressDao(),
        _random = random ?? Random();

  Future<LessonPlan> buildLesson({
    required Category category,
    required int lessonSize,
    Set<String> excludeWordIds = const {},
  }) async {
    final progressRows =
        await _dao.getWordProgressByCategory(categoryId: category.id);
    final progress = <String, WordProgress>{
      for (final entry in progressRows.entries)
        entry.key: WordProgress.fromRow(entry.value),
    };
    return buildLessonFromProgress(
      category: category,
      lessonSize: lessonSize,
      progress: progress,
      excludeWordIds: excludeWordIds,
    );
  }

  LessonPlan buildLessonFromProgress({
    required Category category,
    required int lessonSize,
    required Map<String, WordProgress> progress,
    Set<String> excludeWordIds = const {},
  }) {
    final size = min(lessonSize, category.words.length);
    final reviewCount = switch (size) {
      5 => 2,
      6 => 2,
      8 => 3,
      _ => max(1, (size * 0.34).round()),
    };
    final selected = _selectWords(
      words: category.words,
      progress: progress,
      size: size,
      reviewCount: reviewCount,
      excluded: excludeWordIds,
    );
    final questions = _buildQuestions(
      category: category,
      lessonWords: selected,
      progress: progress,
    );
    return LessonPlan(
      category: category,
      words: List.unmodifiable(selected),
      questions: List.unmodifiable(questions),
    );
  }

  List<Word> _selectWords({
    required List<Word> words,
    required Map<String, WordProgress> progress,
    required int size,
    required int reviewCount,
    required Set<String> excluded,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    int score(Word word) {
      final item =
          progress.values.where((value) => value.wordId == word.id).firstOrNull;
      final exclusionPenalty = excluded.contains(word.id) ? 5 : 0;
      if (item == null || item.quizAttemptCount == 0) {
        return exclusionPenalty;
      }
      if (item.correctStreak == 0) return 1 + exclusionPenalty;
      if (item.correctStreak < 2) return 2 + exclusionPenalty;
      final lastQuiz = item.lastQuizzedAtMs ?? 0;
      if (nowMs - lastQuiz >= _reviewDueAfter.inMilliseconds) {
        return 3 + exclusionPenalty;
      }
      return 4 + exclusionPenalty;
    }

    final buckets = <int, List<Word>>{
      for (var index = 0; index <= 9; index++) index: [],
    };
    for (final word in words) {
      buckets[score(word)]!.add(word);
    }
    for (final entry in buckets.entries) {
      if (entry.key == 3 ||
          entry.key == 4 ||
          entry.key == 8 ||
          entry.key == 9) {
        entry.value.sort((a, b) {
          final aTime = _progressFor(a, progress)?.lastQuizzedAtMs ?? 0;
          final bTime = _progressFor(b, progress)?.lastQuizzedAtMs ?? 0;
          return aTime.compareTo(bTime);
        });
      } else {
        entry.value.shuffle(_random);
      }
    }

    final focusCount = size - reviewCount;
    final result = <Word>[];
    _takeUnique(buckets[0]!, focusCount, result);
    _takeUnique(buckets[1]!, focusCount - result.length, result);
    _takeUnique(buckets[2]!, focusCount - result.length, result);

    final remainingReview = size - result.length;
    _takeUnique(buckets[3]!, remainingReview, result);
    _takeUnique(buckets[4]!, size - result.length, result);

    for (final priority in [0, 1, 2, 3, 4]) {
      _takeUnique(buckets[priority]!, size - result.length, result);
    }
    for (final priority in [5, 6, 7, 8, 9]) {
      _takeUnique(buckets[priority]!, size - result.length, result);
    }
    return result.take(size).toList();
  }

  List<LessonQuestion> _buildQuestions({
    required Category category,
    required List<Word> lessonWords,
    required Map<String, WordProgress> progress,
  }) {
    final targets = [...lessonWords]..shuffle(_random);
    return targets.map((target) {
      final item = progress.values
          .where((value) => value.wordId == target.id)
          .firstOrNull;
      final requestedCount = (item?.correctStreak ?? 0) >= 2 ? 4 : 2;
      final optionCount = min(requestedCount, category.words.length);
      final lessonDistractors = lessonWords
          .where((word) => word.id != target.id)
          .toList()
        ..shuffle(_random);
      final categoryDistractors = category.words
          .where((word) =>
              word.id != target.id &&
              !lessonDistractors.any((item) => item.id == word.id))
          .toList()
        ..shuffle(_random);
      final options = <Word>[target];
      for (final distractor in [...lessonDistractors, ...categoryDistractors]) {
        if (options.length >= optionCount) break;
        options.add(distractor);
      }
      options.shuffle(_random);
      return LessonQuestion(
          target: target, options: List.unmodifiable(options));
    }).toList();
  }

  void _takeUnique(List<Word> source, int count, List<Word> target) {
    if (count <= 0) return;
    while (source.isNotEmpty && count > 0) {
      final word = source.removeAt(0);
      if (target.any((item) => item.id == word.id)) continue;
      target.add(word);
      count--;
    }
  }

  WordProgress? _progressFor(
    Word word,
    Map<String, WordProgress> progress,
  ) {
    return progress.values
        .where((value) => value.wordId == word.id)
        .firstOrNull;
  }
}
