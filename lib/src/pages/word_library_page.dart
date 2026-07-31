import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/services/audio_playback_service.dart';
import 'package:hopenglish/src/services/learning_progress_service.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/widgets/adaptive_image.dart';
import 'package:hopenglish/src/widgets/word_icon.dart';

class WordLibraryPage extends StatefulWidget {
  final List<Category> categories;

  const WordLibraryPage({
    required this.categories,
    super.key,
  });

  @override
  State<WordLibraryPage> createState() => _WordLibraryPageState();
}

class _WordLibraryPageState extends State<WordLibraryPage> {
  int _categoryIndex = 0;

  Category get _category => widget.categories[_categoryIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildCategoryPicker(),
              Expanded(child: _buildWordGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _roundButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('Word Library', style: AppTheme.headlineMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final selected = index == _categoryIndex;
          return InkWell(
            onTap: () => setState(() => _categoryIndex = index),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: AppTheme.durationFast,
              width: 68,
              decoration: BoxDecoration(
                color: selected
                    ? category.color.withValues(alpha: 0.18)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? category.color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(child: _categoryIcon(category, 42)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWordGrid() {
    return GridView.builder(
      key: ValueKey(_category.id),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _category.words.length,
      itemBuilder: (context, index) {
        final word = _category.words[index];
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WordExplorePage(category: _category, word: word),
            ),
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: _category.color.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WordIcon(word: word, size: 72),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    word.name,
                    style: AppTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _categoryIcon(Category category, double size) {
    if (category.hasImage) {
      return AdaptiveImage(
        imagePath: category.imagePath,
        width: size,
        height: size,
        errorWidget:
            Text(category.emoji ?? '', style: TextStyle(fontSize: size * 0.8)),
      );
    }
    return Text(category.emoji ?? '', style: TextStyle(fontSize: size * 0.8));
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
    );
  }
}

class WordExplorePage extends StatefulWidget {
  final Category category;
  final Word word;

  const WordExplorePage({
    required this.category,
    required this.word,
    super.key,
  });

  @override
  State<WordExplorePage> createState() => _WordExplorePageState();
}

class _WordExplorePageState extends State<WordExplorePage> {
  late final AudioPlaybackService _audio;

  @override
  void initState() {
    super.initState();
    _audio = AudioPlaybackService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play(slow: false));
  }

  @override
  void dispose() {
    unawaited(_audio.dispose());
    super.dispose();
  }

  Future<void> _play({required bool slow}) async {
    final played = await _audio.playWord(widget.word, slow: slow);
    if (played) {
      LearningProgressService.instance.recordSuccessfulPlay(
        category: widget.category,
        word: widget.word,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _play(slow: false),
                      child: WordIcon(word: widget.word, size: 220),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.word.name,
                      style: AppTheme.displayLarge
                          .copyWith(color: AppTheme.primary),
                    ),
                    const SizedBox(height: 34),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _audioButton(
                          const Icon(
                            Icons.volume_up_rounded,
                            color: AppTheme.primary,
                            size: 32,
                          ),
                          'Listen',
                          false,
                        ),
                        const SizedBox(width: 18),
                        _audioButton(
                          SvgPicture.asset(
                            'assets/images/icons/solid-slow.svg',
                            width: 24,
                            height: 19,
                            colorFilter: const ColorFilter.mode(
                              AppTheme.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                          'Slow',
                          true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final category = widget.category;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _roundButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          if (category.hasImage)
            AdaptiveImage(
              imagePath: category.imagePath,
              width: 34,
              height: 34,
              errorWidget: Text(
                category.emoji ?? '',
                style: const TextStyle(fontSize: 28),
              ),
            )
          else
            Text(category.emoji ?? '', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.name,
              style: AppTheme.headlineMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
    );
  }

  Widget _audioButton(Widget icon, String label, bool slow) {
    return InkWell(
      onTap: () => _play(slow: slow),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 32,
              child: Center(child: icon),
            ),
            Text(label, style: AppTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
