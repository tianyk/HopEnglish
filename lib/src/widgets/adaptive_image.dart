import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hopenglish/src/libs/utils.dart';

/// 自适应图片组件
///
/// 自动识别并渲染不同类型的图片：
/// - SVG 格式（.svg）
/// - 普通图片（PNG/JPG/GIF 等）
/// - 网络图片（http/https）
/// - 本地资源图片
///
/// 示例：
/// ```dart
/// AdaptiveImage(
///   imagePath: 'assets/images/words/table.svg',
///   width: 180,
///   height: 180,
/// )
/// ```
class AdaptiveImage extends StatelessWidget {
  /// 图片路径（可以是网络 URL 或本地资源路径）
  final String imagePath;

  /// 图片宽度
  final double? width;

  /// 图片高度
  final double? height;

  /// 图片适配模式
  final BoxFit? fit;

  /// 加载中占位符（仅 SVG 支持）
  final Widget? placeholder;

  /// 错误占位符
  final Widget? errorWidget;

  const AdaptiveImage({
    required this.imagePath,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    super.key,
  });

  /// 判断是否为 SVG 格式
  bool get _isSvg => imagePath.toLowerCase().endsWith('.svg');

  /// 判断是否为网络图片
  bool get _isNetwork => isNetworkUrl(imagePath);

  /// 默认错误占位符
  Widget get _defaultErrorWidget {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: width ?? 48,
        color: Colors.grey,
      ),
    );
  }

  /// 默认加载占位符
  Widget get _defaultPlaceholder {
    return Center(
      child: SizedBox(
        width: (width ?? 48) * 0.5,
        height: (height ?? 48) * 0.5,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveErrorWidget = errorWidget ?? _defaultErrorWidget;
    final effectivePlaceholder = placeholder ?? _defaultPlaceholder;

    // SVG 图片
    if (_isSvg) {
      return _isNetwork
          ? SvgPicture.network(
              imagePath,
              width: width,
              height: height,
              fit: fit ?? BoxFit.contain,
              placeholderBuilder: (_) => effectivePlaceholder,
            )
          : SvgPicture.asset(
              imagePath,
              width: width,
              height: height,
              fit: fit ?? BoxFit.contain,
              placeholderBuilder: (_) => effectivePlaceholder,
            );
    }

    // 普通图片（PNG/JPG 等）
    return _isNetwork
        ? Image.network(
            imagePath,
            width: width,
            height: height,
            fit: fit ?? BoxFit.contain,
            errorBuilder: (_, __, ___) => effectiveErrorWidget,
          )
        : Image.asset(
            imagePath,
            width: width,
            height: height,
            fit: fit ?? BoxFit.contain,
            errorBuilder: (_, __, ___) => effectiveErrorWidget,
          );
  }
}

