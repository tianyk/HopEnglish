import 'package:flutter/material.dart';
import 'package:hopenglish/src/libs/logger.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/pages/word_learning_page.dart';
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

  void _handleCategoryTap(BuildContext context, Category category) {
    // 复制单词列表并洗牌（不修改原数据）
    // 每次进入时洗牌一次，本次会话内顺序固定
    final shuffledWords = List<Word>.from(category.words)..shuffle();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WordLearningPage(
          category: category,
          words: shuffledWords,
        ),
      ),
    );
  }
}
