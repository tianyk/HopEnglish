import 'package:hopenglish/src/data/learning_progress_dao.dart';

class AppSettingsService {
  static final AppSettingsService _instance = AppSettingsService._();
  static AppSettingsService get instance => _instance;

  static const int defaultLessonWordCount = 6;
  static const List<int> lessonWordCountOptions = [5, 6, 8];
  static const String _lessonWordCountKey = 'lesson_word_count';

  final LearningProgressDao _dao;

  AppSettingsService._({LearningProgressDao? dao})
      : _dao = dao ?? LearningProgressDao();

  Future<int> getLessonWordCount() async {
    final raw = await _dao.getSetting(_lessonWordCountKey);
    final value = int.tryParse(raw ?? '');
    return lessonWordCountOptions.contains(value)
        ? value!
        : defaultLessonWordCount;
  }

  Future<void> setLessonWordCount(int count) async {
    if (!lessonWordCountOptions.contains(count)) {
      throw ArgumentError.value(count, 'count', '必须是 5、6 或 8');
    }
    await _dao.setSetting(_lessonWordCountKey, '$count');
  }
}
