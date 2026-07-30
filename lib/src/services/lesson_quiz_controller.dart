import 'dart:math';

import 'package:hopenglish/src/learning/learning_models.dart';
import 'package:hopenglish/src/learning/learning_policy.dart';
import 'package:hopenglish/src/models/lesson_plan.dart';
import 'package:hopenglish/src/models/word.dart';

class LessonQuizController {
  final LearningPolicy policy;
  final int randomSeed;
  final String lessonId;
  final List<Word> categoryWords;
  final List<LessonQuestion> questions;
  final Map<String, int> _retryCountByWordId = {};

  LessonQuizController({
    required this.policy,
    required this.randomSeed,
    required this.lessonId,
    required this.categoryWords,
    required List<LessonQuestion> initialQuestions,
  }) : questions = List.of(initialQuestions);

  void scheduleRetry({
    required int currentIndex,
    required LessonQuestion question,
    LearningTransition? transition,
  }) {
    if (question.kind == QuestionKind.reinforcementRetrieval ||
        policy.maxRetriesPerLesson == 0) {
      return;
    }
    final count = _retryCountByWordId[question.target.id] ?? 0;
    final shouldRetry = question.kind == QuestionKind.errorRetry
        ? count < policy.maxRetriesPerLesson
        : transition?.shouldRetryInLesson == true;
    if (!shouldRetry || count >= policy.maxRetriesPerLesson) return;

    final nextCount = count + 1;
    _retryCountByWordId[question.target.id] = nextCount;
    final random = Random(randomSeed + currentIndex * 31 + nextCount * 997);
    final gap = policy.retryMinGap +
        random.nextInt(policy.retryMaxGap - policy.retryMinGap + 1);
    final available = questions.length - currentIndex - 1;
    final missing = max(0, gap - available);
    for (var index = 0; index < missing; index++) {
      questions.add(_buildReinforcementQuestion(
        excludedWordId: question.target.id,
        random: random,
      ));
    }
    final insertAt = min(currentIndex + gap + 1, questions.length);
    questions.insert(
      insertAt,
      _buildTwoChoiceQuestion(
        target: question.target,
        kind: QuestionKind.errorRetry,
        role: LessonRole.failed,
        stage: transition?.nextStage ?? question.stage,
        reviewLevel: transition?.nextReviewLevel ?? question.reviewLevel,
        retryCount: nextCount,
        random: random,
      ),
    );
  }

  LessonQuestion _buildReinforcementQuestion({
    required String excludedWordId,
    required Random random,
  }) {
    final candidates = categoryWords
        .where((word) => word.id != excludedWordId)
        .toList()
      ..shuffle(random);
    return _buildTwoChoiceQuestion(
      target: candidates.first,
      kind: QuestionKind.reinforcementRetrieval,
      role: LessonRole.filler,
      stage: MasteryStage.newWord,
      reviewLevel: 0,
      retryCount: 0,
      random: random,
    );
  }

  LessonQuestion _buildTwoChoiceQuestion({
    required Word target,
    required QuestionKind kind,
    required LessonRole role,
    required MasteryStage stage,
    required int reviewLevel,
    required int retryCount,
    required Random random,
  }) {
    final distractors = categoryWords
        .where((word) => word.id != target.id)
        .toList()
      ..shuffle(random);
    final options = <Word>[target, distractors.first]..shuffle(random);
    return LessonQuestion(
      target: target,
      options: List.unmodifiable(options),
      kind: kind,
      role: role,
      stage: stage,
      reviewLevel: reviewLevel,
      lastQuizLessonId: lessonId,
      retryCount: retryCount,
    );
  }
}
