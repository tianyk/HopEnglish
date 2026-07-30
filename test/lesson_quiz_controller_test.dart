import 'package:flutter_test/flutter_test.dart';
import 'package:hopenglish/src/learning/learning_models.dart';
import 'package:hopenglish/src/learning/learning_policy.dart';
import 'package:hopenglish/src/models/lesson_plan.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/services/lesson_quiz_controller.dart';

void main() {
  test('pads a tail error with reinforcement before retrying', () {
    const dog = Word(id: 'dog', name: 'Dog', emoji: 'dog', audio: 'dog.wav');
    const cat = Word(id: 'cat', name: 'Cat', emoji: 'cat', audio: 'cat.wav');
    const bird =
        Word(id: 'bird', name: 'Bird', emoji: 'bird', audio: 'bird.wav');
    const initial = LessonQuestion(target: dog, options: [dog, cat]);
    final controller = LessonQuizController(
      policy: LearningPolicyV2(),
      randomSeed: 17,
      lessonId: 'lesson',
      categoryWords: const [dog, cat, bird],
      initialQuestions: const [initial],
    );

    controller.scheduleRetry(
      currentIndex: 0,
      question: initial,
      transition: const LearningTransition(
        nextStage: MasteryStage.newWord,
        nextReviewLevel: 0,
        nextReviewAtMs: 0,
        shouldRetryInLesson: true,
        stageChanged: false,
      ),
    );

    final retryIndex = controller.questions.indexWhere(
      (question) => question.kind == QuestionKind.errorRetry,
    );
    expect(retryIndex - 1, inInclusiveRange(2, 4));
    expect(
      controller.questions.skip(1).take(retryIndex - 1).every(
            (question) => question.kind == QuestionKind.reinforcementRetrieval,
          ),
      isTrue,
    );
    expect(controller.questions[retryIndex].target, dog);
  });
}
