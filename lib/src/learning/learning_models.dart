enum MasteryStage {
  newWord,
  acquired,
  consolidating,
  stable;

  static MasteryStage fromStorage(int value) {
    if (value < 0 || value >= values.length) return MasteryStage.newWord;
    return values[value];
  }
}

enum LessonRole {
  failed,
  dueAcquired,
  dueConsolidating,
  dueStable,
  newWord,
  filler,
}

enum QuestionKind {
  initialRetrieval,
  scheduledReview,
  reinforcementRetrieval,
  errorRetry,
}

class LearningCandidate {
  final String wordId;
  final MasteryStage stage;
  final int reviewLevel;
  final int? nextReviewAtMs;
  final int? lastQuizzedAtMs;
  final bool? lastQuizCorrect;
  final String? lastQuizLessonId;
  final int viewCount;
  final int playCount;
  final int correctStreak;

  const LearningCandidate({
    required this.wordId,
    this.stage = MasteryStage.newWord,
    this.reviewLevel = 0,
    this.nextReviewAtMs,
    this.lastQuizzedAtMs,
    this.lastQuizCorrect,
    this.lastQuizLessonId,
    this.viewCount = 0,
    this.playCount = 0,
    this.correctStreak = 0,
  });

  bool get hasFailed => lastQuizCorrect == false;
  int get interestSignal => playCount - viewCount;
}

class LearningPlanInput {
  final List<LearningCandidate> candidates;
  final int requestedSize;
  final int nowMs;
  final String lessonId;
  final int randomSeed;
  final Set<String> excludedWordIds;

  const LearningPlanInput({
    required this.candidates,
    required this.requestedSize,
    required this.nowMs,
    required this.lessonId,
    required this.randomSeed,
    this.excludedWordIds = const {},
  });
}

class SelectedLearningItem {
  final String wordId;
  final LessonRole role;
  final int optionCount;

  const SelectedLearningItem({
    required this.wordId,
    required this.role,
    required this.optionCount,
  });
}

class LearningPlanDecision {
  final int policyVersion;
  final List<SelectedLearningItem> items;

  const LearningPlanDecision({
    required this.policyVersion,
    required this.items,
  });
}

class AttemptInput {
  final MasteryStage currentStage;
  final int currentReviewLevel;
  final String lessonId;
  final String? lastQuizLessonId;
  final QuestionKind questionKind;
  final bool firstAttemptCorrect;
  final int nowMs;

  const AttemptInput({
    required this.currentStage,
    required this.currentReviewLevel,
    required this.lessonId,
    required this.lastQuizLessonId,
    required this.questionKind,
    required this.firstAttemptCorrect,
    required this.nowMs,
  });
}

class LearningTransition {
  final MasteryStage nextStage;
  final int nextReviewLevel;
  final int nextReviewAtMs;
  final bool shouldRetryInLesson;
  final bool stageChanged;

  const LearningTransition({
    required this.nextStage,
    required this.nextReviewLevel,
    required this.nextReviewAtMs,
    required this.shouldRetryInLesson,
    required this.stageChanged,
  });
}
