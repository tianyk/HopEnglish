import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HopEnglishApp());
}

/// HopEnglish 应用入口
class HopEnglishApp extends StatelessWidget {
  const HopEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomePage(),
    );
  }
}

/// 首页 - 主题预览（临时）
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.appName, style: AppTheme.categoryTitle),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(AppStrings.appSlogan, style: AppTheme.body),
                const SizedBox(height: AppTheme.spacingXLarge),
                Expanded(
                  child: _buildCategoryGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      _CategoryItem('🦁', AppStrings.categoryAnimals, AppTheme.categoryAnimals),
      _CategoryItem('🍎', AppStrings.categoryFoods, AppTheme.categoryFoods),
      _CategoryItem('🚗', AppStrings.categoryVehicles, AppTheme.categoryVehicles),
      _CategoryItem('🏃', AppStrings.categoryActions, AppTheme.categoryActions),
      _CategoryItem('🏠', AppStrings.categoryHome, AppTheme.categoryHome),
      _CategoryItem('🎵', AppStrings.categoryMusic, AppTheme.categoryMusic),
      _CategoryItem('🌤️', AppStrings.categoryNature, AppTheme.categoryNature),
    ];
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spacingMedium,
        mainAxisSpacing: AppTheme.spacingMedium,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(category: category);
      },
    );
  }
}

class _CategoryItem {
  final String emoji;
  final String title;
  final Color color;

  _CategoryItem(this.emoji, this.title, this.color);
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: category.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          splashColor: category.color.withValues(alpha: 0.2), // 点击时的水波纹扩散色
          highlightColor: category.color.withValues(alpha: 0.1), // 按住时的背景高亮色
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                category.title,
                style: AppTheme.cardTitle.copyWith(color: category.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
