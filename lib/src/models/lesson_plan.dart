import 'package:equatable/equatable.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/word.dart';

class LessonQuestion extends Equatable {
  final Word target;
  final List<Word> options;

  const LessonQuestion({
    required this.target,
    required this.options,
  });

  @override
  List<Object?> get props => [target, options];
}

class LessonPlan extends Equatable {
  final Category category;
  final List<Word> words;
  final List<LessonQuestion> questions;

  const LessonPlan({
    required this.category,
    required this.words,
    required this.questions,
  });

  @override
  List<Object?> get props => [category, words, questions];
}
