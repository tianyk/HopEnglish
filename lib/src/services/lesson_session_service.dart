import 'dart:math';

import 'package:hopenglish/src/data/learning_progress_dao.dart';
import 'package:hopenglish/src/learning/learning_engine.dart';
import 'package:hopenglish/src/learning/learning_models.dart';
import 'package:hopenglish/src/learning/learning_policy.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/lesson_plan.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/models/word_bucket.dart';

class LessonSessionService {
  static final LessonSessionService _instance = LessonSessionService._();
  static LessonSessionService get instance => _instance;

  final LearningProgressDao _dao;
  final LearningPolicy _policy;

  LessonSessionService._({
    LearningProgressDao? dao,
    LearningPolicy? policy,
  })  : _dao = dao ?? LearningProgressDao(),
        _policy = policy ?? LearningPolicyRegistry.active;

  LearningPolicy get policy => _policy;

  Future<LessonPlan> buildLesson({
    required Category category,
    required int lessonSize,
    Set<String> excludeWordIds = const {},
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final seed = _seedFor(category.id, nowMs);
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
      nowMs: nowMs,
      randomSeed: seed,
      lessonId: '${category.id}:$nowMs:$seed',
    );
  }

  LessonPlan buildLessonFromProgress({
    required Category category,
    required int lessonSize,
    required Map<String, WordProgress> progress,
    Set<String> excludeWordIds = const {},
    int? nowMs,
    int? randomSeed,
    String? lessonId,
  }) {
    final effectiveNow = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final seed = randomSeed ?? _seedFor(category.id, effectiveNow);
    final id = lessonId ?? '${category.id}:$effectiveNow:$seed';
    final candidates = category.words.map((word) {
      final item = progress['${category.id}:${word.id}'];
      return LearningCandidate(
        wordId: word.id,
        stage: item?.masteryStage ?? MasteryStage.newWord,
        reviewLevel: item?.reviewLevel ?? 0,
        nextReviewAtMs: item?.nextReviewAtMs,
        lastQuizzedAtMs: item?.lastQuizzedAtMs,
        lastQuizCorrect: item?.lastQuizCorrect,
        lastQuizLessonId: item?.lastQuizLessonId,
        viewCount: item?.viewCount ?? 0,
        playCount: item?.playCount ?? 0,
        correctStreak: item?.correctStreak ?? 0,
      );
    }).toList();
    final decision = LearningEngine(_policy).createPlan(LearningPlanInput(
      candidates: candidates,
      requestedSize: min(lessonSize, category.words.length),
      nowMs: effectiveNow,
      lessonId: id,
      randomSeed: seed,
      excludedWordIds: excludeWordIds,
    ));
    final wordsById = {for (final word in category.words) word.id: word};
    final random = Random(seed);
    final selectedWords =
        decision.items.map((item) => wordsById[item.wordId]!).toList();
    final studyWords = selectedWords;
    final questionItems = [...decision.items]..shuffle(random);
    final questions = questionItems.map((item) {
      final target = wordsById[item.wordId]!;
      final candidate =
          candidates.firstWhere((value) => value.wordId == item.wordId);
      return LessonQuestion(
        target: target,
        options: _buildOptions(
          target: target,
          selectedWords: selectedWords,
          categoryWords: category.words,
          requestedCount: item.optionCount,
          random: random,
        ),
        kind: item.role == LessonRole.newWord
            ? QuestionKind.initialRetrieval
            : QuestionKind.scheduledReview,
        role: item.role,
        stage: candidate.stage,
        reviewLevel: candidate.reviewLevel,
        lastQuizLessonId: candidate.lastQuizLessonId,
      );
    }).toList();
    return LessonPlan(
      category: category,
      words: List.unmodifiable(selectedWords),
      studyWords: List.unmodifiable(studyWords),
      questions: List.unmodifiable(questions),
      lessonId: id,
      policyVersion: decision.policyVersion,
      randomSeed: seed,
    );
  }

  List<Word> _buildOptions({
    required Word target,
    required List<Word> selectedWords,
    required List<Word> categoryWords,
    required int requestedCount,
    required Random random,
  }) {
    final optionCount = min(requestedCount, categoryWords.length);
    final lessonDistractors = selectedWords
        .where((word) => word.id != target.id)
        .toList()
      ..shuffle(random);
    final selectedIds = lessonDistractors.map((word) => word.id).toSet();
    final categoryDistractors = categoryWords
        .where((word) => word.id != target.id && !selectedIds.contains(word.id))
        .toList()
      ..shuffle(random);
    final options = <Word>[target];
    for (final distractor in [...lessonDistractors, ...categoryDistractors]) {
      if (options.length >= optionCount) break;
      options.add(distractor);
    }
    options.shuffle(random);
    return List.unmodifiable(options);
  }

  int _seedFor(String categoryId, int nowMs) {
    return Object.hash(categoryId, nowMs) & 0x7fffffff;
  }
}
