import 'package:flutter/material.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/widgets/word_icon.dart';

/// 单词目录 BottomSheet
///
/// 展示当前分类下所有单词的缩略图列表
class WordDirectorySheet extends StatelessWidget {
  final Category category;
  final int currentIndex;
  final void Function(int index) onWordSelected;

  const WordDirectorySheet({
    required this.category,
    required this.currentIndex,
    required this.onWordSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Flexible(child: _buildWordGrid()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingSmall),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.textHint,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Row(
        children: [
          Text(
            category.emoji ?? '',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          Text(
            category.name,
            style: AppTheme.headlineMedium.copyWith(
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordGrid() {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMedium,
        0,
        AppTheme.spacingMedium,
        AppTheme.spacingLarge,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppTheme.spacingMedium,
        mainAxisSpacing: AppTheme.spacingMedium,
        childAspectRatio: 0.9,
      ),
      itemCount: category.words.length,
      itemBuilder: (context, index) {
        final isCurrentWord = index == currentIndex;
        return _buildWordItem(index, isCurrentWord);
      },
    );
  }

  Widget _buildWordItem(int index, bool isCurrent) {
    final word = category.words[index];
    return GestureDetector(
      onTap: () => onWordSelected(index),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent ? category.color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isCurrent ? category.color : category.color.withValues(alpha: 0.2),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWordIcon(word),
            const SizedBox(height: 4),
            Text(
              word.name,
              style: AppTheme.titleMedium.copyWith(
                color: isCurrent ? category.color : AppTheme.textPrimary,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordIcon(word) {
    return WordIcon(
      word: word,
      size: 40,
    );
  }
}
