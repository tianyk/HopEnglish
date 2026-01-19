/// 单词分桶类型
///
/// 用于自适应排序时将单词分到不同的桶，然后按配比混排。
enum WordBucket {
  /// 需要复习：很久没见或曝光次数很低
  /// 典型判定：daysSince(lastSeenAt) >= 7 或 viewCount <= 1
  overdue,

  /// 常规巩固：最近见过且次数中等
  warm,

  /// 兴趣奖励：孩子主动重复多（playCount - viewCount 较高）
  favorite,
}

/// 单词进度数据（从数据库读取后的结构化表示）
class WordProgress {
  final String wordKey;
  final String categoryId;
  final String wordId;
  final String wordName;
  final int viewCount;
  final int playCount;
  final int? lastSeenAtMs;
  final int? lastPlayedAtMs;

  const WordProgress({
    required this.wordKey,
    required this.categoryId,
    required this.wordId,
    required this.wordName,
    required this.viewCount,
    required this.playCount,
    this.lastSeenAtMs,
    this.lastPlayedAtMs,
  });

  /// 从数据库行映射构造
  factory WordProgress.fromRow(Map<String, Object?> row) {
    return WordProgress(
      wordKey: row['word_key'] as String,
      categoryId: row['category_id'] as String,
      wordId: row['word_id'] as String,
      wordName: row['word_name'] as String,
      viewCount: (row['view_count'] as int?) ?? 0,
      playCount: (row['play_count'] as int?) ?? 0,
      lastSeenAtMs: row['last_seen_at'] as int?,
      lastPlayedAtMs: row['last_played_at'] as int?,
    );
  }

  /// 计算距离上次看到的天数（用于分桶判定）
  int daysSinceLastSeen(int nowMs) {
    if (lastSeenAtMs == null) return 999; // 从未看过，视为很久
    final deltaMs = nowMs - lastSeenAtMs!;
    return deltaMs ~/ (24 * 60 * 60 * 1000);
  }

  /// 兴趣信号：playCount - viewCount
  /// 正值表示孩子主动重复播放多于被动曝光
  int get interestSignal => playCount - viewCount;
}

/// 单词分桶分类器
class WordBucketClassifier {
  /// Overdue 判定：距上次看到 >= 7 天
  static const int _overdueDaysThreshold = 7;

  /// Overdue 判定：曝光次数 <= 1
  static const int _overdueViewCountThreshold = 1;

  /// Favorite 判定：interestSignal >= 2
  static const int _favoriteInterestThreshold = 2;

  /// 对单个单词进行分桶
  ///
  /// - [progress]：单词进度数据（可能为 null，表示从未学过）
  /// - [nowMs]：当前时间（epoch ms）
  static WordBucket classify({WordProgress? progress, required int nowMs}) {
    if (progress == null) {
      // 从未学过，归入 Overdue（需要覆盖）
      return WordBucket.overdue;
    }
    // 判定 Overdue：很久没见 或 曝光次数很低
    final daysSinceLastSeen = progress.daysSinceLastSeen(nowMs);
    if (daysSinceLastSeen >= _overdueDaysThreshold || progress.viewCount <= _overdueViewCountThreshold) {
      return WordBucket.overdue;
    }
    // 判定 Favorite：孩子主动重复多
    if (progress.interestSignal >= _favoriteInterestThreshold) {
      return WordBucket.favorite;
    }
    // 其他：Warm（常规巩固）
    return WordBucket.warm;
  }
}
