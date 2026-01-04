import 'package:flutter/material.dart';
import 'package:hopenglish/config/category_config.dart';
import 'package:hopenglish/theme/app_theme.dart';
import 'package:hopenglish/widgets/category_card.dart';

/// 首页 - 分类画廊 (Category Hub)
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
                _buildHeader(),
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

  Widget _buildHeader() {
    return const Text(
      'HopEnglish',
      style: AppTheme.headlineMedium,
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
        return CategoryCard(category: category);
      },
    );
  }
}

