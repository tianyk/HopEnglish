import 'package:flutter/material.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/widgets/celebration_overlay.dart';
import 'package:hopenglish/src/widgets/word_directory_sheet.dart';

/// 单词学习页 (Word Learning Page)
///
/// 核心学习页面，沉浸式展示单词
class WordLearningPage extends StatefulWidget {
  final Category category;
  final int initialIndex;

  const WordLearningPage({
    required this.category,
    this.initialIndex = 0,
    super.key,
  });

  @override
  State<WordLearningPage> createState() => _WordLearningPageState();
}

class _WordLearningPageState extends State<WordLearningPage> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // 按钮冷却状态
  bool _isNextButtonCooling = false;
  static const _cooldownDuration = Duration(milliseconds: 500);

  // 庆祝动画状态
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Q弹动画控制器
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Word get _currentWord => widget.category.words[_currentIndex];
  bool get _isLastWord => _currentIndex >= widget.category.words.length - 1;

  void _playWordSound() {
    // TODO: 播放单词发音
    _bounceController.forward(from: 0);
  }

  void _goToNextWord() {
    if (_isNextButtonCooling) return;

    setState(() {
      _isNextButtonCooling = true;
    });

    Future.delayed(_cooldownDuration, () {
      if (mounted) {
        setState(() {
          _isNextButtonCooling = false;
        });
      }
    });

    if (_isLastWord) {
      _startCelebration();
    } else {
      setState(() {
        _currentIndex++;
      });
      // 自动播放新单词发音
      _playWordSound();
    }
  }

  void _goToWord(int index) {
    setState(() {
      _currentIndex = index;
    });
    _playWordSound();
  }

  void _startCelebration() {
    setState(() {
      _showCelebration = true;
    });
  }

  void _onCelebrationComplete() {
    Navigator.of(context).pop();
  }

  void _showWordDirectory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WordDirectorySheet(
        category: widget.category,
        currentIndex: _currentIndex,
        onWordSelected: (index) {
          Navigator.pop(context);
          _goToWord(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildWordDisplay()),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
          if (_showCelebration)
            CelebrationOverlay(
              words: widget.category.words,
              onComplete: _onCelebrationComplete,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: AppTheme.spacingSmall),
          _buildCategoryIcon(),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(child: _buildTitle()),
          _buildDirectoryButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    if (widget.category.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Image.asset(
          widget.category.imagePath,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
        ),
      );
    }
    return Text(
      widget.category.emoji ?? '',
      style: const TextStyle(fontSize: 28),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.category.name,
      style: AppTheme.headlineMedium.copyWith(
        color: widget.category.color,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDirectoryButton() {
    return GestureDetector(
      onTap: _showWordDirectory,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Icon(
          Icons.grid_view_rounded,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildWordDisplay() {
    return GestureDetector(
      onTap: _playWordSound,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: child,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWordIcon(),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildWordName(),
          ],
        ),
      ),
    );
  }

  Widget _buildWordIcon() {
    if (_currentWord.hasImage) {
      return _currentWord.isImageNetwork ? Image.network(_currentWord.imagePath, width: 180, height: 180) : Image.asset(_currentWord.imagePath, width: 180, height: 180);
    }
    return Text(
      _currentWord.emoji ?? '',
      style: const TextStyle(fontSize: 120),
    );
  }

  Widget _buildWordName() {
    return Text(
      _currentWord.name,
      style: AppTheme.displayLarge.copyWith(
        color: widget.category.color,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: _buildNextButton(),
    );
  }

  Widget _buildNextButton() {
    final buttonColor = _isNextButtonCooling ? widget.category.color.withValues(alpha: 0.5) : widget.category.color;

    return GestureDetector(
      onTap: _goToNextWord,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLastWord ? '完成' : '下一个',
              style: AppTheme.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Icon(
              _isLastWord ? Icons.check_rounded : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
