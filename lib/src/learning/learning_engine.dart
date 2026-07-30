import 'dart:math';

import 'package:hopenglish/src/learning/learning_models.dart';
import 'package:hopenglish/src/learning/learning_policy.dart';

class LearningEngine {
  final LearningPolicy policy;

  const LearningEngine(this.policy);

  LearningPlanDecision createPlan(LearningPlanInput input) {
    if (policy.version == 1) return _createLegacyPlan(input);
    final random = Random(input.randomSeed);
    final buckets = <LessonRole, List<LearningCandidate>>{
      for (final role in LessonRole.values) role: [],
    };

    for (final candidate in input.candidates) {
      buckets[_roleFor(candidate, input.nowMs)]!.add(candidate);
    }

    for (final entry in buckets.entries) {
      final tieRanks = <String, int>{
        for (final candidate in entry.value)
          candidate.wordId: random.nextInt(1 << 31),
      };
      entry.value.sort((a, b) {
        final excludedComparison = _exclusionRank(
          a,
          entry.key,
          input.excludedWordIds,
        ).compareTo(_exclusionRank(
          b,
          entry.key,
          input.excludedWordIds,
        ));
        if (excludedComparison != 0) return excludedComparison;
        final timeComparison =
            _priorityTime(a, entry.key).compareTo(_priorityTime(b, entry.key));
        if (timeComparison != 0) return timeComparison;
        final interestComparison = b.interestSignal.compareTo(a.interestSignal);
        if (interestComparison != 0) return interestComparison;
        return tieRanks[a.wordId]!.compareTo(tieRanks[b.wordId]!);
      });
    }

    final selected = <SelectedLearningItem>[];
    void take(LessonRole role, int count) {
      if (count <= 0) return;
      for (final candidate in buckets[role]!) {
        if (selected.length >= input.requestedSize || count <= 0) break;
        if (selected.any((item) => item.wordId == candidate.wordId)) continue;
        selected.add(SelectedLearningItem(
          wordId: candidate.wordId,
          role: role,
          optionCount: _optionCount(candidate),
        ));
        count--;
      }
    }

    for (final role in const [
      LessonRole.failed,
      LessonRole.dueAcquired,
      LessonRole.dueConsolidating,
      LessonRole.dueStable,
    ]) {
      take(role, input.requestedSize - selected.length);
    }

    take(
      LessonRole.newWord,
      min(policy.maxNewWords(input.requestedSize),
          input.requestedSize - selected.length),
    );
    take(LessonRole.filler, input.requestedSize - selected.length);
    return LearningPlanDecision(
      policyVersion: policy.version,
      items: List.unmodifiable(selected),
    );
  }

  LearningPlanDecision _createLegacyPlan(LearningPlanInput input) {
    final random = Random(input.randomSeed);
    int score(LearningCandidate candidate) {
      final penalty = input.excludedWordIds.contains(candidate.wordId) ? 5 : 0;
      if (candidate.lastQuizzedAtMs == null) return penalty;
      if (candidate.correctStreak == 0) return 1 + penalty;
      if (candidate.correctStreak < 2) return 2 + penalty;
      if (input.nowMs - candidate.lastQuizzedAtMs! >=
          const Duration(days: 7).inMilliseconds) {
        return 3 + penalty;
      }
      return 4 + penalty;
    }

    final buckets = <int, List<LearningCandidate>>{
      for (var index = 0; index <= 9; index++) index: [],
    };
    for (final candidate in input.candidates) {
      buckets[score(candidate)]!.add(candidate);
    }
    for (final entry in buckets.entries) {
      if ({3, 4, 8, 9}.contains(entry.key)) {
        entry.value.sort((a, b) =>
            (a.lastQuizzedAtMs ?? 0).compareTo(b.lastQuizzedAtMs ?? 0));
      } else {
        entry.value.shuffle(random);
      }
    }

    final size = min(input.requestedSize, input.candidates.length);
    final reviewCount = switch (size) {
      5 || 6 => 2,
      8 => 3,
      _ => max(1, (size * 0.34).round()),
    };
    final selected = <LearningCandidate>[];
    void take(int bucket, int count) {
      if (count <= 0) return;
      for (final candidate in buckets[bucket]!) {
        if (count <= 0 || selected.length >= size) break;
        if (selected.any((item) => item.wordId == candidate.wordId)) continue;
        selected.add(candidate);
        count--;
      }
    }

    final focusCount = size - reviewCount;
    take(0, focusCount);
    take(1, focusCount - selected.length);
    take(2, focusCount - selected.length);
    take(3, size - selected.length);
    take(4, size - selected.length);
    for (final bucket in const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]) {
      take(bucket, size - selected.length);
    }
    return LearningPlanDecision(
      policyVersion: policy.version,
      items: selected.map((candidate) {
        final candidateScore = score(candidate) % 5;
        final role = switch (candidateScore) {
          0 => LessonRole.newWord,
          1 => LessonRole.failed,
          2 => LessonRole.dueAcquired,
          3 => LessonRole.dueStable,
          _ => LessonRole.filler,
        };
        return SelectedLearningItem(
          wordId: candidate.wordId,
          role: role,
          optionCount: candidate.correctStreak >= 2
              ? policy.stableOptionCount
              : policy.newWordOptionCount,
        );
      }).toList(),
    );
  }

  LearningTransition applyAttempt(AttemptInput input) {
    if (input.questionKind == QuestionKind.errorRetry ||
        input.questionKind == QuestionKind.reinforcementRetrieval) {
      return LearningTransition(
        nextStage: input.currentStage,
        nextReviewLevel: input.currentReviewLevel,
        nextReviewAtMs: input.nowMs,
        shouldRetryInLesson: !input.firstAttemptCorrect,
        stageChanged: false,
      );
    }

    if (!input.firstAttemptCorrect) {
      final nextStage = switch (input.currentStage) {
        MasteryStage.newWord => MasteryStage.newWord,
        MasteryStage.acquired => MasteryStage.acquired,
        MasteryStage.consolidating => MasteryStage.acquired,
        MasteryStage.stable => MasteryStage.consolidating,
      };
      return LearningTransition(
        nextStage: nextStage,
        nextReviewLevel: 0,
        nextReviewAtMs: input.nowMs,
        shouldRetryInLesson: policy.maxRetriesPerLesson > 0,
        stageChanged: nextStage != input.currentStage,
      );
    }

    if (input.lastQuizLessonId == input.lessonId) {
      return LearningTransition(
        nextStage: input.currentStage,
        nextReviewLevel: input.currentReviewLevel,
        nextReviewAtMs: input.nowMs,
        shouldRetryInLesson: false,
        stageChanged: false,
      );
    }

    return switch (input.currentStage) {
      MasteryStage.newWord => _success(
          input,
          MasteryStage.acquired,
          0,
          policy.acquiredInterval,
        ),
      MasteryStage.acquired => _success(
          input,
          MasteryStage.consolidating,
          0,
          policy.consolidatingInterval,
        ),
      MasteryStage.consolidating => _success(
          input,
          MasteryStage.stable,
          0,
          policy.stableIntervals.first,
        ),
      MasteryStage.stable => _stableSuccess(input),
    };
  }

  LearningTransition _stableSuccess(AttemptInput input) {
    final nextLevel =
        min(input.currentReviewLevel + 1, policy.stableIntervals.length - 1);
    return _success(
      input,
      MasteryStage.stable,
      nextLevel,
      policy.stableIntervals[nextLevel],
    );
  }

  LearningTransition _success(
    AttemptInput input,
    MasteryStage stage,
    int level,
    Duration interval,
  ) {
    return LearningTransition(
      nextStage: stage,
      nextReviewLevel: level,
      nextReviewAtMs: input.nowMs + interval.inMilliseconds,
      shouldRetryInLesson: false,
      stageChanged:
          stage != input.currentStage || level != input.currentReviewLevel,
    );
  }

  LessonRole _roleFor(LearningCandidate candidate, int nowMs) {
    if (candidate.hasFailed) return LessonRole.failed;
    final due =
        candidate.nextReviewAtMs == null || candidate.nextReviewAtMs! <= nowMs;
    return switch (candidate.stage) {
      MasteryStage.newWord => LessonRole.newWord,
      MasteryStage.acquired => due ? LessonRole.dueAcquired : LessonRole.filler,
      MasteryStage.consolidating =>
        due ? LessonRole.dueConsolidating : LessonRole.filler,
      MasteryStage.stable => due ? LessonRole.dueStable : LessonRole.filler,
    };
  }

  int _optionCount(LearningCandidate candidate) {
    return switch (candidate.stage) {
      MasteryStage.newWord ||
      MasteryStage.acquired =>
        policy.newWordOptionCount,
      MasteryStage.consolidating ||
      MasteryStage.stable =>
        policy.stableOptionCount,
    };
  }

  int _priorityTime(LearningCandidate candidate, LessonRole role) {
    if (role == LessonRole.dueAcquired ||
        role == LessonRole.dueConsolidating ||
        role == LessonRole.dueStable) {
      return candidate.nextReviewAtMs ?? 0;
    }
    return candidate.lastQuizzedAtMs ?? 0;
  }

  int _exclusionRank(
    LearningCandidate candidate,
    LessonRole role,
    Set<String> excluded,
  ) {
    if (role != LessonRole.newWord && role != LessonRole.filler) return 0;
    return excluded.contains(candidate.wordId) ? 1 : 0;
  }
}
