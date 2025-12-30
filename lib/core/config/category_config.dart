import 'package:flutter/material.dart';

/// 学习分类配置
///
/// 集中管理所有分类的 id、emoji、名称、主题色
/// 便于统一维护和后续扩展（如国际化、动态加载等）
class CategoryConfig {
  CategoryConfig._();

  /// 所有学习分类
  static const List<CategoryItem> categories = [
    CategoryItem(
      id: 'animals',
      emoji: '🦁',
      name: '动物世界',
      color: Color(0xFFFFB347),
    ),
    CategoryItem(
      id: 'foods',
      emoji: '🍎',
      name: '美味食物',
      color: Color(0xFFFF5C7A),
    ),
    CategoryItem(
      id: 'vehicles',
      emoji: '🚗',
      name: '交通工具',
      color: Color(0xFF2EC4B6),
    ),
    CategoryItem(
      id: 'actions',
      emoji: '🏃',
      name: '动作状态',
      color: Color(0xFFFFD166),
    ),
    CategoryItem(
      id: 'home',
      emoji: '🏠',
      name: '居家生活',
      color: Color(0xFFC3A6FF),
    ),
    CategoryItem(
      id: 'music',
      emoji: '🎵',
      name: '乐器声音',
      color: Color(0xFFFF85A2),
    ),
    CategoryItem(
      id: 'nature',
      emoji: '🌤️',
      name: '天气自然',
      color: Color(0xFF4CBF8A),
    ),
  ];

  /// 获取所有分类的主题色（用于撒花粒子等场景）
  static List<Color> get allColors => categories.map((c) => c.color).toList();

  /// 根据 id 获取分类
  static CategoryItem? findById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// 分类项数据模型
class CategoryItem {
  /// 分类唯一标识（用于路由、数据存储等）
  final String id;

  /// 分类图标 emoji
  final String emoji;

  /// 分类显示名称
  final String name;

  /// 分类主题色
  final Color color;

  const CategoryItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.color,
  });
}
