import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/libs/utils.dart';

/// 分类数据模型
///
/// 表示一个学习主题分类，如"动物"、"食物"等
class Category extends Equatable {
  /// 唯一标识，用于路由和存储
  final String id;

  /// 分类图标（emoji），与 image 二选一
  final String? emoji;

  /// 分类图片路径，与 emoji 二选一，优先使用
  final String? image;

  /// 显示名称（英文）
  final String name;

  /// 主题色
  final Color color;

  /// 单词列表
  final List<Word> words;

  const Category({
    required this.id,
    this.emoji,
    this.image,
    required this.name,
    required this.color,
    required this.words,
  }) : assert(emoji != null || image != null, 'emoji 和 image 至少需要一个');

  /// 是否有图片
  bool get hasImage => image != null && image!.isNotEmpty;

  /// 图片是否为网络地址
  bool get isImageNetwork => image != null && isNetworkUrl(image!);

  /// 图片是否为 SVG 格式
  bool get isImageSvg => image != null && image!.toLowerCase().endsWith('.svg');

  /// 单词数量
  int get wordCount => words.length;

  /// 获取图片完整路径（自动判断本地/网络）
  String get imagePath {
    if (image == null) return '';
    return isNetworkUrl(image!) ? image! : 'assets/images/categories/$image';
  }

  /// 从 JSON 创建实例
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      emoji: json['emoji'] as String?,
      image: json['image'] as String?,
      name: json['name'] as String,
      color: _parseColor(json['color'] as String),
      words: (json['words'] as List<dynamic>).map((w) => Word.fromJson(w as Map<String, dynamic>)).toList(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (emoji != null) 'emoji': emoji,
      if (image != null) 'image': image,
      'name': name,
      'color': _colorToHex(color),
      'words': words.map((w) => w.toJson()).toList(),
    };
  }

  /// 解析十六进制颜色字符串 (#RRGGBB)
  static Color _parseColor(String hex) {
    final hexCode = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  /// 颜色转十六进制字符串
  static String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  @override
  List<Object?> get props => [id, emoji, image, name, color, words];

  @override
  String toString() {
    return 'Category(id: $id, name: $name, wordCount: $wordCount)';
  }
}
