import 'package:flutter/material.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/widgets/adaptive_image.dart';

/// 单词图标组件
///
/// 优先显示单词的图片（使用 AdaptiveImage），如果没有图片则显示 emoji。
/// 自动处理图片和 emoji 的尺寸比例，确保视觉效果一致。
///
/// 示例：
/// ```dart
/// WordIcon(
///   word: myWord,
///   size: 180,
/// )
/// ```
class WordIcon extends StatelessWidget {
  /// 单词数据
  final Word word;

  /// 图标尺寸（图片的宽高）
  final double size;

  /// emoji 相对图片的大小比例
  /// 默认 0.78，因为 emoji 的视觉重量通常比图片更"重"
  final double emojiSizeRatio;

  /// 图片适配模式
  final BoxFit? fit;

  /// 错误时的占位符
  final Widget? errorWidget;

  const WordIcon({
    required this.word,
    required this.size,
    this.emojiSizeRatio = 0.78,
    this.fit,
    this.errorWidget,
    super.key,
  });

  /// 计算 emoji 的字体大小
  double get _emojiFontSize => size * emojiSizeRatio;

  @override
  Widget build(BuildContext context) {
    // 优先使用图片
    if (word.hasImage) {
      return AdaptiveImage(
        imagePath: word.imagePath,
        width: size,
        height: size,
        fit: fit ?? BoxFit.contain,
        errorWidget: errorWidget,
      );
    }

    // 回退到 emoji
    return Text(
      word.emoji ?? '',
      style: TextStyle(fontSize: _emojiFontSize),
    );
  }
}

