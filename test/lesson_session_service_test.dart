import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/models/word_bucket.dart';
import 'package:hopenglish/src/services/lesson_session_service.dart';

void main() {
  group('LessonSessionService', () {
    final category = Category(
      id: 'animals',
      emoji: 'A',
      name: 'Animals',
      color: Colors.orange,
      words: List.generate(
        12,
        (index) => Word(
          id: 'word$index',
          name: 'Word $index',
          emoji: '$index',
          audio: 'word${index}_normal.wav',
        ),
      ),
    );

    test('builds exact 5, 6, and 8 word lessons', () {
      for (final size in [5, 6, 8]) {
        final plan = LessonSessionService.instance.buildLessonFromProgress(
          category: category,
          lessonSize: size,
          progress: const {},
        );

        expect(plan.words, hasLength(size));
        expect(plan.questions, hasLength(size));
        expect(
          plan.questions.every((question) => question.options.length == 2),
          isTrue,
        );
        expect(plan.words.map((word) => word.id).toSet(), hasLength(size));
      }
    });

    test('avoids the previous group when enough words remain', () {
      final plan = LessonSessionService.instance.buildLessonFromProgress(
        category: category,
        lessonSize: 5,
        progress: const {},
        excludeWordIds: const {'word0', 'word1', 'word2', 'word3', 'word4'},
      );

      expect(
        plan.words.any(
          (word) => const {'word0', 'word1', 'word2', 'word3', 'word4'}
              .contains(word.id),
        ),
        isFalse,
      );
    });

    test('promotes familiar words to four-choice questions', () {
      final smallCategory = Category(
        id: category.id,
        emoji: category.emoji,
        name: category.name,
        color: category.color,
        words: category.words.take(4).toList(),
      );
      final familiar = WordProgress(
        wordKey: 'animals:word0',
        categoryId: 'animals',
        wordId: 'word0',
        wordName: 'Word 0',
        viewCount: 3,
        playCount: 3,
        quizAttemptCount: 2,
        quizCorrectCount: 2,
        correctStreak: 2,
        lastQuizzedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      final plan = LessonSessionService.instance.buildLessonFromProgress(
        category: smallCategory,
        lessonSize: 4,
        progress: {'animals:word0': familiar},
      );

      final question = plan.questions
          .firstWhere((question) => question.target.id == 'word0');
      expect(question.options, hasLength(4));
    });

    test('fills focus slots with unseen words before mastered reviews', () {
      final progress = <String, WordProgress>{
        for (var index = 3; index < category.words.length; index++)
          'animals:word$index': WordProgress(
            wordKey: 'animals:word$index',
            categoryId: 'animals',
            wordId: 'word$index',
            wordName: 'Word $index',
            viewCount: 0,
            playCount: 0,
            quizAttemptCount: 3,
            quizCorrectCount: 3,
            correctStreak: 3,
            lastQuizzedAtMs: DateTime.now().millisecondsSinceEpoch,
          ),
      };

      final plan = LessonSessionService.instance.buildLessonFromProgress(
        category: category,
        lessonSize: 5,
        progress: progress,
      );

      expect(
        plan.words.map((word) => word.id),
        containsAll(const ['word0', 'word1', 'word2']),
      );
    });

    test('chooses the longest overdue reviews first', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final day = const Duration(days: 1).inMilliseconds;
      final progress = <String, WordProgress>{
        for (var index = 3; index < category.words.length; index++)
          'animals:word$index': WordProgress(
            wordKey: 'animals:word$index',
            categoryId: 'animals',
            wordId: 'word$index',
            wordName: 'Word $index',
            viewCount: 0,
            playCount: 0,
            quizAttemptCount: 3,
            quizCorrectCount: 3,
            correctStreak: 3,
            lastQuizzedAtMs: now -
                (switch (index) {
                      3 => 10,
                      4 => 8,
                      5 => 9,
                      _ => 1,
                    } *
                    day),
          ),
      };

      final plan = LessonSessionService.instance.buildLessonFromProgress(
        category: category,
        lessonSize: 5,
        progress: progress,
      );
      final ids = plan.words.map((word) => word.id).toSet();

      expect(ids, containsAll(const ['word3', 'word5']));
      expect(ids, isNot(contains('word4')));
    });
  });
}
