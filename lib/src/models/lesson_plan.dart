import 'package:equatable/equatable.dart';
import 'package:hopenglish/src/learning/learning_models.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/word.dart';

class LessonQuestion extends Equatable {
  final Word target;
  final List<Word> options;
  final QuestionKind kind;
  final LessonRole role;
  final MasteryStage stage;
  final int reviewLevel;
  final String? lastQuizLessonId;
  final int retryCount;

  const LessonQuestion({
    required this.target,
    required this.options,
    this.kind = QuestionKind.initialRetrieval,
    this.role = LessonRole.newWord,
    this.stage = MasteryStage.newWord,
    this.reviewLevel = 0,
    this.lastQuizLessonId,
    this.retryCount = 0,
  });

  @override
  List<Object?> get props => [
        target,
        options,
        kind,
        role,
        stage,
        reviewLevel,
        lastQuizLessonId,
        retryCount,
      ];
}

class LessonPlan extends Equatable {
  final Category category;
  final List<Word> words;
  final List<LessonQuestion> questions;
  final List<Word> studyWords;
  final String lessonId;
  final int policyVersion;
  final int randomSeed;

  const LessonPlan({
    required this.category,
    required this.words,
    required this.questions,
    List<Word>? studyWords,
    this.lessonId = 'legacy',
    this.policyVersion = 1,
    this.randomSeed = 0,
  }) : studyWords = studyWords ?? words;

  @override
  List<Object?> get props => [
        category,
        words,
        questions,
        studyWords,
        lessonId,
        policyVersion,
        randomSeed,
      ];
}
