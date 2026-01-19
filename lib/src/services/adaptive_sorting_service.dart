import 'dart:math';

import 'package:hopenglish/src/data/learning_progress_dao.dart';
import 'package:hopenglish/src/libs/logger.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/learning_mode.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/models/word_bucket.dart';

final _logger = Logger.getLogger();

/// 自适应排序服务
///
/// 根据学习进度数据，为每次进入主题生成优化的单词顺序：
/// 1. 读取 lastSessionAt → 判断 LearningMode（日常/复习/久别）
/// 2. 读取所有 word_progress → 分桶（Overdue/Warm/Favorite）
/// 3. 根据 Mode 决定配比，混排生成顺序
///
/// 设计原则：
/// - 会话内固定，会话间自适应
/// - 覆盖/复习为主，偏好为辅
/// - 前几个位置最关键（适配短 session）
class AdaptiveSortingService {
  static final AdaptiveSortingService _instance = AdaptiveSortingService._();
  static AdaptiveSortingService get instance => _instance;

  final LearningProgressDao _dao;
  final Random _random;

  AdaptiveSortingService._({Random? random})
      : _dao = LearningProgressDao(),
        _random = random ?? Random();

  /// 生成本次会话的单词顺序
  ///
  /// - [category]：当前主题
  /// - [words]：主题下所有单词（原始顺序）
  /// - [now]：当前时间（用于时间分档和分桶判定）
  ///
  /// 返回：排序后的单词列表（会话内固定）
  Future<List<Word>> generateSessionOrder({
    required Category category,
    required List<Word> words,
    DateTime? now,
  }) async {
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    if (words.isEmpty) return [];
    // 1. 判断学习模式
    final lastSessionAtMs = await _dao.getCategoryLastSessionAt(categoryId: category.id);
    final mode = LearningModeResolver.resolve(lastSessionAtMs: lastSessionAtMs, nowMs: nowMs);
    _logger.debug('generateSessionOrder', {
      'categoryId': category.id,
      'mode': mode.name,
      'lastSessionAtMs': lastSessionAtMs,
    });
    // 2. 读取所有单词的进度数据
    final progressMap = await _dao.getWordProgressByCategory(categoryId: category.id);
    // 3. 对每个单词分桶
    final buckets = <WordBucket, List<Word>>{
      WordBucket.overdue: [],
      WordBucket.warm: [],
      WordBucket.favorite: [],
    };
    for (final word in words) {
      final wordKey = '${category.id}:${word.id}';
      final row = progressMap[wordKey];
      final progress = row != null ? WordProgress.fromRow(row) : null;
      final bucket = WordBucketClassifier.classify(progress: progress, nowMs: nowMs);
      buckets[bucket]!.add(word);
    }
    _logger.debug('buckets', {
      'overdue': buckets[WordBucket.overdue]!.length,
      'warm': buckets[WordBucket.warm]!.length,
      'favorite': buckets[WordBucket.favorite]!.length,
    });
    // 4. 根据模式决定配比，生成排序
    return _buildOrder(mode: mode, buckets: buckets, totalCount: words.length);
  }

  /// 根据模式和分桶结果生成最终顺序
  ///
  /// 配比规则（PRD D 节）：
  /// - 日常巩固：Overdue 2 + Warm 3（最多穿插 1 个 Favorite）
  /// - 复习加强：Overdue 3 + Warm 2
  /// - 久别重启：Favorite/熟悉 2 + Overdue 2 + Warm/新 1
  List<Word> _buildOrder({
    required LearningMode mode,
    required Map<WordBucket, List<Word>> buckets,
    required int totalCount,
  }) {
    // 桶内先随机打乱
    for (final list in buckets.values) {
      list.shuffle(_random);
    }
    final overdue = buckets[WordBucket.overdue]!;
    final warm = buckets[WordBucket.warm]!;
    final favorite = buckets[WordBucket.favorite]!;
    final result = <Word>[];
    // 根据模式决定前 5 个位置的配比
    switch (mode) {
      case LearningMode.daily:
        // 日常巩固：Overdue 2 + Warm 3（最多穿插 1 个 Favorite）
        _takeUpTo(overdue, 2, result);
        _takeUpTo(warm, 3, result);
        _takeUpTo(favorite, 1, result);
      case LearningMode.review:
        // 复习加强：Overdue 3 + Warm 2
        _takeUpTo(overdue, 3, result);
        _takeUpTo(warm, 2, result);
      case LearningMode.restart:
        // 久别重启：Favorite/熟悉 2 + Overdue 2 + Warm/新 1
        _takeUpTo(favorite, 2, result);
        _takeUpTo(overdue, 2, result);
        _takeUpTo(warm, 1, result);
    }
    // 剩余的单词追加到末尾（混合后轻随机）
    final remaining = <Word>[...overdue, ...warm, ...favorite];
    remaining.shuffle(_random);
    result.addAll(remaining);
    _logger.debug('finalOrder', {
      'mode': mode.name,
      'resultCount': result.length,
      'first5': result.take(5).map((w) => w.name).toList(),
    });
    return result;
  }

  /// 从源列表取出最多 n 个元素放入目标列表，同时从源列表移除
  void _takeUpTo(List<Word> source, int n, List<Word> target) {
    final count = min(n, source.length);
    for (var i = 0; i < count; i++) {
      target.add(source.removeAt(0));
    }
  }
}
