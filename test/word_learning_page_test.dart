import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/learning/learning_models.dart';
import 'package:hopenglish/src/models/lesson_plan.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/pages/celebration_page.dart';
import 'package:hopenglish/src/pages/word_learning_page.dart';
import 'package:hopenglish/src/services/audio_playback_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class _FakeAudioController implements AudioPlaybackController {
  final firstPlayback = Completer<bool>();
  Completer<bool>? pendingPlayback;
  int wordPlayCount = 0;
  int encouragementPlayCount = 0;
  int stopCount = 0;
  bool? lastSlow;
  Completer<void>? pendingEncouragement;

  @override
  Future<bool> playWord(
    Word word, {
    bool slow = false,
    bool waitForCompletion = true,
  }) {
    wordPlayCount++;
    lastSlow = slow;
    if (wordPlayCount == 1) return firstPlayback.future;
    final pending = pendingPlayback;
    pendingPlayback = null;
    if (pending != null) return pending.future;
    return Future.value(true);
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playCompletion() async {}

  @override
  Future<void> playEncouragement() {
    encouragementPlayCount++;
    return pendingEncouragement?.future ?? Future.value();
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }
}

void main() {
  testWidgets('manual replay does not relock Next after the initial listen',
      (tester) async {
    const dog = Word(id: 'dog', name: 'Dog', emoji: 'dog', audio: 'dog.wav');
    const cat = Word(id: 'cat', name: 'Cat', emoji: 'cat', audio: 'cat.wav');
    const category = Category(
      id: 'animals',
      emoji: 'animals',
      name: 'Animals',
      color: Colors.orange,
      words: [dog, cat],
    );
    const plan = LessonPlan(
      category: category,
      words: [dog],
      questions: [
        LessonQuestion(target: dog, options: [dog, cat]),
      ],
    );
    final audio = _FakeAudioController();

    await tester.pumpWidget(
      MaterialApp(
        home: WordLearningPage(plan: plan, lessonSize: 5, audio: audio),
      ),
    );
    await tester.pump();

    GestureDetector next() => tester
        .widget<GestureDetector>(find.byKey(const ValueKey('lesson-next')));
    expect(next().onTap, isNull);

    audio.firstPlayback.complete(true);
    await tester.pump();
    expect(next().onTap, isNotNull);

    final slowPlayback = Completer<bool>();
    audio.pendingPlayback = slowPlayback;
    await tester.tap(find.byKey(const ValueKey('listen-slow')));
    await tester.pump();
    expect(audio.lastSlow, isTrue);
    expect(next().onTap, isNotNull);

    final playCountAfterSlow = audio.wordPlayCount;
    await tester.tap(find.byKey(const ValueKey('listen-normal')));
    await tester.pump();
    expect(audio.wordPlayCount, playCountAfterSlow);

    slowPlayback.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 501));

    final imagePlayback = Completer<bool>();
    audio.pendingPlayback = imagePlayback;
    await tester.tap(find.byKey(const ValueKey('learning-image')));
    await tester.pump();
    expect(audio.lastSlow, isFalse);
    expect(next().onTap, isNotNull);
    imagePlayback.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 501));

    final normalPlayback = Completer<bool>();
    audio.pendingPlayback = normalPlayback;
    await tester.tap(find.byKey(const ValueKey('listen-normal')));
    await tester.pump();
    expect(audio.lastSlow, isFalse);
    expect(next().onTap, isNotNull);
    normalPlayback.complete(true);
    await tester.pump();

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('listen-normal'))).height,
      tester.getSize(find.byKey(const ValueKey('listen-slow'))).height,
    );
  });

  testWidgets('manual playback during the initial listen keeps Next locked',
      (tester) async {
    const dog = Word(id: 'dog', name: 'Dog', emoji: 'dog', audio: 'dog.wav');
    const cat = Word(id: 'cat', name: 'Cat', emoji: 'cat', audio: 'cat.wav');
    const category = Category(
      id: 'animals',
      emoji: 'animals',
      name: 'Animals',
      color: Colors.orange,
      words: [dog, cat],
    );
    const plan = LessonPlan(
      category: category,
      words: [dog],
      questions: [
        LessonQuestion(target: dog, options: [dog, cat]),
      ],
    );
    final audio = _FakeAudioController();

    await tester.pumpWidget(
      MaterialApp(
        home: WordLearningPage(plan: plan, lessonSize: 5, audio: audio),
      ),
    );
    await tester.pump();

    GestureDetector next() => tester
        .widget<GestureDetector>(find.byKey(const ValueKey('lesson-next')));
    expect(next().onTap, isNull);

    final manualPlayback = Completer<bool>();
    audio.pendingPlayback = manualPlayback;
    await tester.tap(find.byKey(const ValueKey('listen-slow')));
    await tester.pump();
    expect(next().onTap, isNull);

    manualPlayback.complete(true);
    await tester.pump();
    expect(next().onTap, isNotNull);

    audio.firstPlayback.complete(false);
    await tester.pump();
  });

  testWidgets('quiz keeps the child on the question after a wrong answer',
      (tester) async {
    const dog = Word(id: 'dog', name: 'Dog', emoji: 'dog', audio: 'dog.wav');
    const cat = Word(id: 'cat', name: 'Cat', emoji: 'cat', audio: 'cat.wav');
    const category = Category(
      id: 'animals',
      emoji: 'animals',
      name: 'Animals',
      color: Colors.orange,
      words: [dog, cat],
    );
    const plan = LessonPlan(
      category: category,
      words: [dog],
      questions: [
        LessonQuestion(target: dog, options: [dog, cat]),
        LessonQuestion(target: cat, options: [cat, dog]),
      ],
    );
    final audio = _FakeAudioController();

    await tester.pumpWidget(
      MaterialApp(
        home: WordLearningPage(plan: plan, lessonSize: 5, audio: audio),
      ),
    );
    await tester.pump();
    audio.firstPlayback.complete(true);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lesson-next')));
    await tester.pump();

    expect(find.byKey(const ValueKey('answer-dog')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-cat')), findsOneWidget);
    expect(find.byKey(const ValueKey('two-choice-layout')), findsOneWidget);
    final dogCard = tester.getRect(find.byKey(const ValueKey('answer-dog')));
    expect(dogCard.height, greaterThan(dogCard.width));
    final instruction = tester.getRect(find.text('Tap the picture'));
    expect(dogCard.top - instruction.bottom, inInclusiveRange(40, 52));

    await tester.tap(find.byKey(const ValueKey('answer-cat')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quiz-dog')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-cat')), findsOneWidget);
    expect(find.byType(CelebrationPage), findsNothing);

    await tester.tap(find.byKey(const ValueKey('answer-dog')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quiz-cat')), findsOneWidget);
  });

  testWidgets('four-choice questions use a 2 by 2 grid', (tester) async {
    const dog = Word(id: 'dog', name: 'Dog', emoji: 'dog', audio: 'dog.wav');
    const cat = Word(id: 'cat', name: 'Cat', emoji: 'cat', audio: 'cat.wav');
    const fish =
        Word(id: 'fish', name: 'Fish', emoji: 'fish', audio: 'fish.wav');
    const bird =
        Word(id: 'bird', name: 'Bird', emoji: 'bird', audio: 'bird.wav');
    const category = Category(
      id: 'animals',
      emoji: 'animals',
      name: 'Animals',
      color: Colors.orange,
      words: [dog, cat, fish, bird],
    );
    const plan = LessonPlan(
      category: category,
      words: [dog],
      questions: [
        LessonQuestion(target: dog, options: [dog, cat, fish, bird]),
      ],
    );
    final audio = _FakeAudioController();

    await tester.pumpWidget(
      MaterialApp(
        home: WordLearningPage(plan: plan, lessonSize: 5, audio: audio),
      ),
    );
    await tester.pump();
    audio.firstPlayback.complete(true);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lesson-next')));
    await tester.pump();

    expect(find.byKey(const ValueKey('four-choice-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('two-choice-layout')), findsNothing);
    expect(find.byKey(const ValueKey('answer-dog')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-cat')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-fish')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-bird')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quiz waits for encouragement before playing the next word',
      (tester) async {
    const dog = Word(id: 'dog', name: 'Dog', emoji: 'dog', audio: 'dog.wav');
    const cat = Word(id: 'cat', name: 'Cat', emoji: 'cat', audio: 'cat.wav');
    const category = Category(
      id: 'animals',
      emoji: 'animals',
      name: 'Animals',
      color: Colors.orange,
      words: [dog, cat],
    );
    const plan = LessonPlan(
      category: category,
      words: [dog, cat],
      studyWords: [],
      questions: [
        LessonQuestion(
          target: dog,
          options: [dog, cat],
          kind: QuestionKind.reinforcementRetrieval,
        ),
        LessonQuestion(
          target: cat,
          options: [cat, dog],
          kind: QuestionKind.reinforcementRetrieval,
        ),
      ],
    );
    final audio = _FakeAudioController();
    audio.pendingEncouragement = Completer<void>();

    await tester.pumpWidget(MaterialApp(
      home: WordLearningPage(plan: plan, lessonSize: 5, audio: audio),
    ));
    await tester.pump();
    audio.firstPlayback.complete(true);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('answer-dog')));
    await tester.pump();

    expect(audio.encouragementPlayCount, 1);
    expect(find.byKey(const ValueKey('quiz-dog')), findsOneWidget);
    expect(audio.wordPlayCount, 1);

    audio.pendingEncouragement!.complete();
    await tester.pump();

    expect(find.byKey(const ValueKey('quiz-cat')), findsOneWidget);
    expect(audio.wordPlayCount, 2);
  });

  testWidgets('last quiz answer skips encouragement before celebration',
      (tester) async {
    const dog = Word(id: 'dog', name: 'Dog', emoji: 'dog', audio: 'dog.wav');
    const cat = Word(id: 'cat', name: 'Cat', emoji: 'cat', audio: 'cat.wav');
    const category = Category(
      id: 'animals',
      emoji: 'animals',
      name: 'Animals',
      color: Colors.orange,
      words: [dog, cat],
    );
    const plan = LessonPlan(
      category: category,
      words: [dog],
      studyWords: [],
      questions: [
        LessonQuestion(
          target: dog,
          options: [dog, cat],
          kind: QuestionKind.reinforcementRetrieval,
        ),
      ],
    );
    final audio = _FakeAudioController();

    await tester.pumpWidget(MaterialApp(
      home: WordLearningPage(plan: plan, lessonSize: 5, audio: audio),
    ));
    await tester.pump();
    audio.firstPlayback.complete(true);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('answer-dog')));
    await tester.pump(const Duration(milliseconds: 399));

    expect(audio.encouragementPlayCount, 0);
    expect(find.byType(CelebrationPage), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(audio.encouragementPlayCount, 0);
    expect(audio.stopCount, 1);
    expect(find.byType(CelebrationPage), findsOneWidget);
  });

  testWidgets('wrong answers are retried after at least two other questions',
      (tester) async {
    const dog = Word(id: 'dog', name: 'Dog', emoji: 'dog', audio: 'dog.wav');
    const cat = Word(id: 'cat', name: 'Cat', emoji: 'cat', audio: 'cat.wav');
    const bird =
        Word(id: 'bird', name: 'Bird', emoji: 'bird', audio: 'bird.wav');
    const fish =
        Word(id: 'fish', name: 'Fish', emoji: 'fish', audio: 'fish.wav');
    const cow = Word(id: 'cow', name: 'Cow', emoji: 'cow', audio: 'cow.wav');
    const horse =
        Word(id: 'horse', name: 'Horse', emoji: 'horse', audio: 'horse.wav');
    const category = Category(
      id: 'animals',
      emoji: 'animals',
      name: 'Animals',
      color: Colors.orange,
      words: [dog, cat, bird, fish, cow, horse],
    );
    const plan = LessonPlan(
      category: category,
      words: [dog, bird, fish, cow, horse],
      studyWords: [],
      lessonId: 'lesson-v2',
      policyVersion: 2,
      randomSeed: 17,
      questions: [
        LessonQuestion(target: dog, options: [dog, cat]),
        LessonQuestion(target: bird, options: [bird, cat]),
        LessonQuestion(target: fish, options: [fish, cat]),
        LessonQuestion(target: cow, options: [cow, cat]),
        LessonQuestion(target: horse, options: [horse, cat]),
      ],
    );
    final audio = _FakeAudioController();
    var recordedAttempts = 0;

    Future<LearningTransition> recorder({
      required LessonQuestion question,
      required bool firstAttemptCorrect,
    }) async {
      recordedAttempts++;
      return LearningTransition(
        nextStage:
            firstAttemptCorrect ? MasteryStage.acquired : MasteryStage.newWord,
        nextReviewLevel: 0,
        nextReviewAtMs: 0,
        shouldRetryInLesson: !firstAttemptCorrect,
        stageChanged: firstAttemptCorrect,
      );
    }

    await tester.pumpWidget(MaterialApp(
      home: WordLearningPage(
        plan: plan,
        lessonSize: 5,
        audio: audio,
        attemptRecorder: recorder,
      ),
    ));
    await tester.pump();
    audio.firstPlayback.complete(true);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('answer-cat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quiz-dog')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('answer-dog')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quiz-dog')), findsNothing);

    var interveningQuestions = 0;
    for (final target in [bird, fish, cow, horse]) {
      if (find.byKey(const ValueKey('quiz-dog')).evaluate().isNotEmpty) break;
      expect(
        find.byKey(ValueKey('quiz-${target.id}')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ValueKey('answer-${target.id}')));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      interveningQuestions++;
    }

    expect(interveningQuestions, inInclusiveRange(2, 4));
    expect(find.byKey(const ValueKey('quiz-dog')), findsOneWidget);
    expect(recordedAttempts, interveningQuestions + 1);
  });
}
