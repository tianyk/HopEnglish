import 'package:flutter/material.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/widgets/adaptive_image.dart';

/// 分类卡片组件
class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryCard({
    required this.category,
    this.onTap,
    super.key,
  });

  static const double _borderWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    final outerRadius = BorderRadius.circular(AppTheme.radiusLarge);
    final innerRadius = BorderRadius.circular(AppTheme.radiusLarge - _borderWidth);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: outerRadius,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: category.color.withValues(alpha: 0.3),
          width: _borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: innerRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: category.color.withValues(alpha: 0.2),
            highlightColor: category.color.withValues(alpha: 0.1),
            onTap: onTap,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon(),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(category.name, style: AppTheme.titleMedium),
      ],
    );
  }

  Widget _buildIcon() {
    if (category.hasImage) {
      return AdaptiveImage(
        imagePath: category.imagePath,
        width: 48,
        height: 48,
      );
    }
    return Text(category.emoji ?? '', style: const TextStyle(fontSize: 48));
  }
}
