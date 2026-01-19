/// 学习模式（时间分档）
///
/// 根据距离上次学习该主题的间隔时间，将进入主题时的策略分为三档。
/// 用于自适应排序时决定 Overdue/Warm/Favorite 的配比。
enum LearningMode {
  /// 日常巩固：距上次 < 2 天
  /// 行为倾向：覆盖更均匀，少量复习穿插
  daily,

  /// 复习加强：距上次 2-7 天
  /// 行为倾向：复习比例更高，避免陌生感过强
  review,

  /// 久别重启：距上次 ≥ 7 天（或首次学习）
  /// 行为倾向：先熟后新，先用熟悉/偏好词恢复规则感与动机
  restart,
}

/// 学习模式解析器
class LearningModeResolver {
  /// 2 天阈值（毫秒）
  static const int _twoDaysMs = 2 * 24 * 60 * 60 * 1000;

  /// 7 天阈值（毫秒）
  static const int _sevenDaysMs = 7 * 24 * 60 * 60 * 1000;

  /// 根据上次学习时间判断当前学习模式
  ///
  /// - [lastSessionAtMs]：上次进入该主题的时间（epoch ms），null 表示首次学习
  /// - [nowMs]：当前时间（epoch ms）
  static LearningMode resolve({required int? lastSessionAtMs, required int nowMs}) {
    if (lastSessionAtMs == null) {
      // 首次学习，视为久别重启
      return LearningMode.restart;
    }
    final deltaMs = nowMs - lastSessionAtMs;
    if (deltaMs < _twoDaysMs) {
      return LearningMode.daily;
    } else if (deltaMs < _sevenDaysMs) {
      return LearningMode.review;
    } else {
      return LearningMode.restart;
    }
  }
}
