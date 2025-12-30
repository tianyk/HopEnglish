import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/category_config.dart';
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
                // const SizedBox(height: AppTheme.spacingSmall),
                // Text(AppStrings.appSlogan, style: AppTheme.body),
                const SizedBox(height: AppTheme.spacingLarge),
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
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spacingMedium,
        mainAxisSpacing: AppTheme.spacingMedium,
        childAspectRatio: 1.1,
      ),
      itemCount: CategoryConfig.categories.length,
      itemBuilder: (context, index) {
        final category = CategoryConfig.categories[index];
        return _CategoryCard(category: category);
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem category;

  const _CategoryCard({required this.category});

  static const _borderWidth = 2.0;

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
                  category.name,
                  style: AppTheme.cardTitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
