import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/pages/celebration_page.dart';
import 'package:hopenglish/src/services/learning_progress_service.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/widgets/word_directory_sheet.dart';
import 'package:hopenglish/src/widgets/word_icon.dart';

/// 单词学习页 (Word Learning Page)
///
/// 核心学习页面，沉浸式展示单词
class WordLearningPage extends StatefulWidget {
  final Category category;

  /// 洗牌后的单词列表
  /// 每次进入时由调用方洗牌，本次会话内顺序固定
  final List<Word> words;
  final int initialIndex;

  const WordLearningPage({
    required this.category,
    required this.words,
    this.initialIndex = 0,
    super.key,
  });

  @override
  State<WordLearningPage> createState() => _WordLearningPageState();
}

class _WordLearningPageState extends State<WordLearningPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _currentIndex;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AudioPlayer _audioPlayer;

  /// 学习进度记录（vNext）：记录"看到/听到 + 时间"，用于后续自适应排序。
  final LearningProgressService _progressService = LearningProgressService.instance;

  /// 记录切后台的时间戳（用于 2 分钟会话恢复阈值判断）。
  int? _pausedAtMs;

  /// 会话恢复阈值：切后台/锁屏超过该阈值后返回，视为新会话（用于久别/复习分档）。
  static const Duration _sessionResumeThreshold = Duration(minutes: 2);

  // 按钮冷却状态
  bool _isNextButtonCooling = false;
  static const _cooldownDuration = Duration(milliseconds: 500);

  // 单词图标尺寸
  static const double _wordIconSize = 180;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);

    // 初始化音频播放器
    _audioPlayer = AudioPlayer();

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

    // 进入页面后：记录会话锚点 + 看到 + 听到
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _touchSession();
      _recordView();
      _playWordSound();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 记录离开时间，便于调试/统计（以及未来更稳的会话边界处理）
    _progressService.saveCategoryExitedAt(categoryId: widget.category.id);
    _bounceController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Word get _currentWord => widget.words[_currentIndex];
  bool get _isLastWord => _currentIndex >= widget.words.length - 1;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (state == AppLifecycleState.paused) {
      _pausedAtMs = nowMs;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final pausedAtMs = _pausedAtMs;
      _pausedAtMs = null;
      if (pausedAtMs == null) return;
      final deltaMs = nowMs - pausedAtMs;
      // 超过阈值则认为新会话：更新主题 lastSessionAt（用于“日常/久别重启”判断）
      if (deltaMs >= _sessionResumeThreshold.inMilliseconds) {
        _touchSession();
      }
    }
  }

  void _touchSession() {
    _progressService.touchCategorySession(categoryId: widget.category.id);
  }

  /// 记录"看到一次"（viewCount +1）。
  void _recordView() {
    _progressService.recordView(category: widget.category, word: _currentWord);
  }

  void _playWordSound() async {
    // 记录"听到一次"：以"触发播放"为准（播放成功与否不影响口径），服务层做连点合并。
    _progressService.recordPlay(category: widget.category, word: _currentWord);
    // 播放Q弹动画
    _bounceController.forward(from: 0);

    // 播放单词音频
    try {
      await _audioPlayer.stop(); // 停止当前播放

      if (_currentWord.isAudioNetwork) {
        // 网络音频：直接使用完整 URL
        await _audioPlayer.play(UrlSource(_currentWord.audioPath));
      } else {
        // 本地音频：使用相对于 assets/ 的路径（去掉 assets/ 前缀）
        // audioPath = 'assets/audio/words/lion_normal.wav'
        // AssetSource 需要 = 'audio/words/lion_normal.wav'
        final assetPath = _currentWord.audioPath.replaceFirst('assets/', '');
        await _audioPlayer.play(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('播放音频失败: $e');
    }
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
      _recordView();
      _playWordSound();
    }
  }

  void _goToWord(int index) {
    setState(() {
      _currentIndex = index;
    });
    _recordView();
    _playWordSound();
  }

  void _startCelebration() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CelebrationPage(
          words: widget.words,
          themeColor: widget.category.color,
        ),
      ),
    );
  }

  void _showWordDirectory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WordDirectorySheet(
        category: widget.category,
        words: widget.words,
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
      body: Container(
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
        color: AppTheme.textPrimary,
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
    return WordIcon(
      word: _currentWord,
      size: _wordIconSize,
    );
  }

  Widget _buildWordName() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _currentWord.name,
          style: AppTheme.displayLarge.copyWith(
            color: AppTheme.primary,
          ),
          maxLines: 1,
        ),
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
    final buttonColor = _isNextButtonCooling ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.primary;

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
              'Next',
              style: AppTheme.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
