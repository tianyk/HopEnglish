import 'package:flutter/material.dart';
import 'package:hopenglish/config/category_config.dart';
import 'package:hopenglish/theme/app_theme.dart';

/// 分类卡片组件
class CategoryCard extends StatelessWidget {
  final CategoryItem category;

  const CategoryCard({
    required this.category,
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
            onTap: () => _handleTap(context),
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
        Text(
          category.emoji,
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          category.name,
          style: AppTheme.cardTitle,
        ),
      ],
    );
  }

  void _handleTap(BuildContext context) {
    // TODO: 导航到单词矩阵列表页
  }
}

