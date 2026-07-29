import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/lesson_plan.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/pages/word_learning_page.dart';
import 'package:hopenglish/src/services/audio_playback_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class _FakeAudioController implements AudioPlaybackController {
  final firstPlayback = Completer<bool>();
  Completer<bool>? pendingPlayback;
  int wordPlayCount = 0;
  bool? lastSlow;

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
  Future<void> playEncouragement() async {}

  @override
  Future<void> stop() async {}
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
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const ValueKey('quiz-dog')), findsOneWidget);
    expect(find.byKey(const ValueKey('answer-cat')), findsOneWidget);
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
}
