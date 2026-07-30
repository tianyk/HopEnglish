import 'package:flutter_test/flutter_test.dart';
import 'package:hopenglish/src/learning/learning_engine.dart';
import 'package:hopenglish/src/learning/learning_models.dart';
import 'package:hopenglish/src/learning/learning_policy.dart';

void main() {
  final engine = LearningEngine(LearningPolicyV2());
  const day = Duration(days: 1);
  const now = 100 * Duration.millisecondsPerDay;

  group('LearningEngine planning', () {
    test('v1 policy keeps the legacy full-size new lesson', () {
      final legacy = LearningEngine(LearningPolicyV1()).createPlan(
        LearningPlanInput(
          candidates: List.generate(
            12,
            (index) => LearningCandidate(wordId: 'word$index'),
          ),
          requestedSize: 5,
          nowMs: now,
          lessonId: 'legacy',
          randomSeed: 42,
        ),
      );

      expect(legacy.policyVersion, 1);
      expect(legacy.items, hasLength(5));
    });

    test('is deterministic and caps new words', () {
      final candidates = List.generate(
        12,
        (index) => LearningCandidate(wordId: 'word$index'),
      );
      const input = LearningPlanInput(
        candidates: [],
        requestedSize: 5,
        nowMs: now,
        lessonId: 'lesson',
        randomSeed: 42,
      );
      final first = engine.createPlan(LearningPlanInput(
        candidates: candidates,
        requestedSize: input.requestedSize,
        nowMs: input.nowMs,
        lessonId: input.lessonId,
        randomSeed: input.randomSeed,
      ));
      final second = engine.createPlan(LearningPlanInput(
        candidates: candidates,
        requestedSize: input.requestedSize,
        nowMs: input.nowMs,
        lessonId: input.lessonId,
        randomSeed: input.randomSeed,
      ));

      expect(first.items.map((item) => item.wordId),
          orderedEquals(second.items.map((item) => item.wordId)));
      expect(first.items, hasLength(3));
      expect(
        first.items.every((item) => item.role == LessonRole.newWord),
        isTrue,
      );
    });

    test('failed and due items override exclusion and new words', () {
      final decision = engine.createPlan(LearningPlanInput(
        candidates: [
          const LearningCandidate(
            wordId: 'failed',
            stage: MasteryStage.acquired,
            lastQuizCorrect: false,
          ),
          const LearningCandidate(
            wordId: 'due',
            stage: MasteryStage.stable,
            nextReviewAtMs: now - 1,
          ),
          ...List.generate(
            8,
            (index) => LearningCandidate(wordId: 'new$index'),
          ),
        ],
        requestedSize: 5,
        nowMs: now,
        lessonId: 'lesson',
        randomSeed: 7,
        excludedWordIds: const {'failed', 'due'},
      ));

      expect(decision.items.first.wordId, 'failed');
      expect(decision.items[1].wordId, 'due');
      expect(
        decision.items.where((item) => item.role == LessonRole.newWord),
        hasLength(3),
      );
    });

    test('sorts due stable words by deadline across review levels', () {
      final decision = engine.createPlan(const LearningPlanInput(
        candidates: [
          LearningCandidate(
            wordId: 'level2-one-day-overdue',
            stage: MasteryStage.stable,
            reviewLevel: 2,
            lastQuizzedAtMs: now - 31 * Duration.millisecondsPerDay,
            nextReviewAtMs: now - Duration.millisecondsPerDay,
          ),
          LearningCandidate(
            wordId: 'level0-three-days-overdue',
            stage: MasteryStage.stable,
            reviewLevel: 0,
            lastQuizzedAtMs: now - 10 * Duration.millisecondsPerDay,
            nextReviewAtMs: now - 3 * Duration.millisecondsPerDay,
          ),
        ],
        requestedSize: 2,
        nowMs: now,
        lessonId: 'lesson',
        randomSeed: 7,
      ));

      expect(
        decision.items.map((item) => item.wordId),
        orderedEquals(const [
          'level0-three-days-overdue',
          'level2-one-day-overdue',
        ]),
      );
    });
  });

  group('LearningEngine transitions', () {
    LearningTransition apply(
      MasteryStage stage,
      bool correct, {
      int level = 0,
      QuestionKind kind = QuestionKind.scheduledReview,
      String? lastLesson,
    }) {
      return engine.applyAttempt(AttemptInput(
        currentStage: stage,
        currentReviewLevel: level,
        lessonId: 'lesson-2',
        lastQuizLessonId: lastLesson,
        questionKind: kind,
        firstAttemptCorrect: correct,
        nowMs: now,
      ));
    }

    test('advances through all stages with configured intervals', () {
      final acquired = apply(MasteryStage.newWord, true);
      expect(acquired.nextStage, MasteryStage.acquired);
      expect(acquired.nextReviewAtMs, now + day.inMilliseconds);

      final consolidating = apply(MasteryStage.acquired, true);
      expect(consolidating.nextStage, MasteryStage.consolidating);
      expect(consolidating.nextReviewAtMs, now + 3 * day.inMilliseconds);

      final stable = apply(MasteryStage.consolidating, true);
      expect(stable.nextStage, MasteryStage.stable);
      expect(stable.nextReviewAtMs, now + 7 * day.inMilliseconds);

      final stableL1 = apply(MasteryStage.stable, true);
      expect(stableL1.nextReviewLevel, 1);
      expect(stableL1.nextReviewAtMs, now + 14 * day.inMilliseconds);

      final stableL2 = apply(MasteryStage.stable, true, level: 1);
      expect(stableL2.nextReviewLevel, 2);
      expect(stableL2.nextReviewAtMs, now + 30 * day.inMilliseconds);

      final capped = apply(MasteryStage.stable, true, level: 2);
      expect(capped.nextReviewLevel, 2);
      expect(capped.nextReviewAtMs, now + 30 * day.inMilliseconds);
    });

    test('does not advance twice in one lesson or on an error retry', () {
      final sameLesson = apply(
        MasteryStage.acquired,
        true,
        lastLesson: 'lesson-2',
      );
      expect(sameLesson.nextStage, MasteryStage.acquired);

      final retry = apply(
        MasteryStage.acquired,
        true,
        kind: QuestionKind.errorRetry,
      );
      expect(retry.nextStage, MasteryStage.acquired);
      expect(retry.stageChanged, isFalse);
    });

    test('demotes lapses conservatively and requests retry', () {
      expect(
        apply(MasteryStage.newWord, false).nextStage,
        MasteryStage.newWord,
      );
      expect(
        apply(MasteryStage.acquired, false).nextStage,
        MasteryStage.acquired,
      );
      expect(
        apply(MasteryStage.consolidating, false).nextStage,
        MasteryStage.acquired,
      );
      final stableFailure = apply(MasteryStage.stable, false, level: 2);
      expect(stableFailure.nextStage, MasteryStage.consolidating);
      expect(stableFailure.nextReviewLevel, 0);
      expect(stableFailure.shouldRetryInLesson, isTrue);
    });
  });
}
