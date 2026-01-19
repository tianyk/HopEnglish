import 'package:hopenglish/src/data/app_database.dart';
import 'package:hopenglish/src/data/learning_progress_dao.dart';
import 'package:hopenglish/src/libs/logger.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/word.dart';

final _logger = Logger.getLogger();

/// 学习进度服务（vNext）
///
/// 负责把"看到/听到 + 时间"以稳定口径写入本地数据库（SQLite + sqflite），用于后续自适应排序。
///
/// 口径（与 PRD/技术文档一致）：
/// - viewCount：单词成为当前展示词（有效停留后）记 1 次（由 UI 层控制停留阈值）
/// - playCount：触发播放记 1 次（服务层做短时间合并，避免连点噪声）
/// - lastSeenAt/lastPlayedAt：随计数更新（epoch ms）
/// - categoryProgress.lastSessionAt：进入主题时更新（用于"日常/久别重启"分档）
///
/// 设计原则：
/// - 进度记录是辅助功能，不应影响主流程（所有写入操作静默失败，仅记录日志）
/// - UI 层应使用 fire-and-forget 方式调用，不阻塞交互
class LearningProgressService {
  static final LearningProgressService _instance = LearningProgressService._();
  static LearningProgressService get instance => _instance;

  final LearningProgressDao _dao;

  /// 记录每个 wordKey 上一次"计入 playCount"的时间戳，用于连点合并。
  final Map<String, int> _lastPlayRecordedAtByWordKey = {};

  /// 同一单词在该时间窗口内重复触发播放，只计 1 次（避免物理连点把兴趣信号放大成噪声）。
  final Duration _playCountMergeWindow;

  LearningProgressService._({
    Duration playCountMergeWindow = const Duration(milliseconds: 1000),
  })  : _dao = LearningProgressDao(),
        _playCountMergeWindow = playCountMergeWindow;

  /// 轻量探测数据库连接是否可用（建议在启动时调用）。
  ///
  /// 目的：提前触发 openDatabase / 建表，避免首次进入学习页时承担"第一次开库 + 建表"的延迟。
  Future<void> ping() async {
    _logger.debug('ping');
    try {
      await AppDatabase.ping();
      _logger.debug('ping ok');
    } catch (e, st) {
      _logger.error('ping failed', error: e, stackTrace: st);
    }
  }

  /// 构建学习项的稳定主键（`$categoryId:$wordId`）。
  String buildWordKey({required String categoryId, required String wordId}) => '$categoryId:$wordId';

  /// 进入主题学习页时调用，用于记录主题级会话锚点（lastSessionAt）。
  void touchCategorySession({required String categoryId, DateTime? now}) {
    _logger.debug('touchCategorySession', {'categoryId': categoryId});
    _runSafely('touchCategorySession', () async {
      await _dao.touchCategorySession(categoryId: categoryId, nowMs: (now ?? DateTime.now()).millisecondsSinceEpoch);
    });
  }

  /// 离开主题学习页时调用（可选），用于记录 lastExitedAt（调试/统计/会话边界更稳）。
  void saveCategoryExitedAt({required String categoryId, DateTime? now}) {
    _logger.debug('saveCategoryExitedAt', {'categoryId': categoryId});
    _runSafely('saveCategoryExitedAt', () async {
      await _dao.saveCategoryExitedAt(categoryId: categoryId, nowMs: (now ?? DateTime.now()).millisecondsSinceEpoch);
    });
  }

  /// 记录"看到"一次（viewCount +1，并刷新 lastSeenAt）。
  void recordView({required Category category, required Word word, DateTime? now}) {
    final wordKey = buildWordKey(categoryId: category.id, wordId: word.id);
    _logger.debug('recordView', {'wordKey': wordKey, 'wordName': word.name});
    _runSafely('recordView', () async {
      await _dao.incrementView(
        wordKey: wordKey,
        categoryId: category.id,
        wordId: word.id,
        wordName: word.name,
        nowMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
      );
    });
  }

  /// 记录"听到"一次（playCount +1，并刷新 lastPlayedAt）。
  ///
  /// 注意：服务层会对同一 wordKey 的短时间重复播放做合并计数（见 _playCountMergeWindow）。
  void recordPlay({required Category category, required Word word, DateTime? now}) {
    final wordKey = buildWordKey(categoryId: category.id, wordId: word.id);
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    // 连点合并：同一词短时间内重复播放只计 1 次
    final lastRecordedAtMs = _lastPlayRecordedAtByWordKey[wordKey];
    if (lastRecordedAtMs != null) {
      final deltaMs = nowMs - lastRecordedAtMs;
      if (deltaMs >= 0 && deltaMs < _playCountMergeWindow.inMilliseconds) {
        _logger.debug('recordPlay skipped (merge window)', {'wordKey': wordKey, 'deltaMs': deltaMs});
        return;
      }
    }
    _logger.debug('recordPlay', {'wordKey': wordKey, 'wordName': word.name});
    _lastPlayRecordedAtByWordKey[wordKey] = nowMs;
    _runSafely('recordPlay', () async {
      await _dao.incrementPlay(
        wordKey: wordKey,
        categoryId: category.id,
        wordId: word.id,
        wordName: word.name,
        nowMs: nowMs,
      );
    });
  }

  /// 安全执行异步操作（静默失败，仅记录日志）。
  void _runSafely(String operation, Future<void> Function() action) {
    action().catchError((Object e, StackTrace st) {
      _logger.error('$operation failed', error: e, stackTrace: st);
    });
  }
}
