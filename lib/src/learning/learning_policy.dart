abstract class LearningPolicy {
  int get version;
  Map<int, int> get maxNewWordsByLessonSize;
  int get retryMinGap;
  int get retryMaxGap;
  int get maxRetriesPerLesson;
  Duration get acquiredInterval;
  Duration get consolidatingInterval;
  List<Duration> get stableIntervals;
  int get newWordOptionCount;
  int get stableOptionCount;

  int maxNewWords(int lessonSize) {
    return maxNewWordsByLessonSize[lessonSize] ??
        ((lessonSize + 1) ~/ 2).clamp(1, lessonSize);
  }
}

class LearningPolicyV1 extends LearningPolicy {
  @override
  int get version => 1;
  @override
  Map<int, int> get maxNewWordsByLessonSize => const {5: 5, 6: 6, 8: 8};
  @override
  int get retryMinGap => 0;
  @override
  int get retryMaxGap => 0;
  @override
  int get maxRetriesPerLesson => 0;
  @override
  Duration get acquiredInterval => const Duration(days: 7);
  @override
  Duration get consolidatingInterval => const Duration(days: 7);
  @override
  List<Duration> get stableIntervals => const [Duration(days: 7)];
  @override
  int get newWordOptionCount => 2;
  @override
  int get stableOptionCount => 4;
}

class LearningPolicyV2 extends LearningPolicy {
  @override
  int get version => 2;
  @override
  Map<int, int> get maxNewWordsByLessonSize => const {5: 3, 6: 3, 8: 4};
  @override
  int get retryMinGap => 2;
  @override
  int get retryMaxGap => 4;
  @override
  int get maxRetriesPerLesson => 2;
  @override
  Duration get acquiredInterval => const Duration(days: 1);
  @override
  Duration get consolidatingInterval => const Duration(days: 3);
  @override
  List<Duration> get stableIntervals => const [
        Duration(days: 7),
        Duration(days: 14),
        Duration(days: 30),
      ];
  @override
  int get newWordOptionCount => 2;
  @override
  int get stableOptionCount => 4;
}

class LearningPolicyRegistry {
  static const _configuredVersion = String.fromEnvironment(
    'LEARNING_POLICY_VERSION',
    defaultValue: '2',
  );

  static LearningPolicy get active =>
      _configuredVersion == '1' ? LearningPolicyV1() : LearningPolicyV2();

  static LearningPolicy forVersion(int version) =>
      version == 1 ? LearningPolicyV1() : LearningPolicyV2();
}
