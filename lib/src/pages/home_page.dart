import 'package:flutter/material.dart';
import 'package:hopenglish/src/libs/logger.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/pages/word_learning_page.dart';
import 'package:hopenglish/src/services/adaptive_sorting_service.dart';
import 'package:hopenglish/src/services/category_service.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/widgets/category_card.dart';

final _logger = Logger.getLogger();

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
                Expanded(child: _buildCategoryGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text('HopEnglish', style: AppTheme.headlineMedium);
  }

  Widget _buildCategoryGrid() {
    return FutureBuilder<List<Category>>(
      future: CategoryService.loadCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          _logger.error('加载分类失败', error: snapshot.error);
          return Center(child: Text('加载失败: ${snapshot.error}'));
        }

        final categories = snapshot.data ?? [];
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
            return CategoryCard(
              category: category,
              onTap: () => _handleCategoryTap(context, category),
            );
          },
        );
      },
    );
  }

  void _handleCategoryTap(BuildContext context, Category category) async {
    // 使用自适应排序服务生成本次会话的单词顺序
    // 根据学习进度数据（viewCount/playCount/lastSeenAt）+ 时间分档（日常/复习/久别）
    // 生成优化的顺序，会话内固定
    final sortedWords = await AdaptiveSortingService.instance.generateSessionOrder(
      category: category,
      words: category.words,
    );
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WordLearningPage(
          category: category,
          words: sortedWords,
        ),
      ),
    );
  }
}
