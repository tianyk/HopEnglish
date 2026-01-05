import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/libs/utils.dart';

/// 庆祝撒花动画粒子数据
class _CelebrationParticle {
  /// 粒子内容：emoji 文本（优先级低）
  final String? emoji;

  /// 粒子内容：图片路径/URL（优先级高）
  final String? image;

  /// 粒子中心 x 坐标 (0.0-1.0，相对于屏幕宽度)
  double x;

  /// 粒子中心 y 坐标 (0.0-1.0，相对于屏幕高度)
  double y;

  /// 水平速度（每帧移动的距离比例）
  double velocityX;

  /// 垂直速度（每帧移动的距离比例）
  double velocityY;

  /// 旋转角度（弧度）
  double rotation;

  /// 旋转速度（每帧旋转的弧度）
  double rotationSpeed;

  /// 缩放比例
  final double scale;

  _CelebrationParticle({
    this.emoji,
    this.image,
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.scale,
  });
}

/// 独立庆祝页面
///
/// 学习完成时展示：
/// - 从底部喷射单词 emoji + 装饰 emoji
/// - 中央 "Well done!" 大字（弹出动画）
/// - Done 按钮 + 倒计时
/// - 语音表扬
class CelebrationPage extends StatefulWidget {
  final List<Word> words;
  final Color themeColor;

  /// 重力加速度
  /// 控制粒子下落的速度，值越大下落越快
  /// 1 为全重力，0.5 为半重力，0 为无重力
  final double gravity;

  /// 速度保留系数 (0-1)
  /// 每帧保留的速度比例，值越大粒子飞得越远
  /// 0.9 表示每帧保留 90% 速度（损失 10%）
  final double decay;

  /// 初始速度（像素）
  /// 控制粒子喷射的高度和力度，值越大喷得越高
  final double startVelocity;

  /// 扩散角度（度）
  /// 粒子喷射的扩散范围，45 表示在发射角度 ±22.5° 范围内
  final double spread;

  /// 粒子总数
  /// 控制整体粒子密度，值越大粒子越多
  final int particleCount;

  const CelebrationPage({
    required this.words,
    required this.themeColor,
    this.gravity = 1.0,
    this.decay = 0.988,
    this.startVelocity = 0.035,
    this.spread = 45,
    this.particleCount = 50,
    super.key,
  });

  @override
  State<CelebrationPage> createState() => _CelebrationPageState();
}

class _CelebrationPageState extends State<CelebrationPage> with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _textController;
  late Animation<double> _textScaleAnimation;
  late List<_CelebrationParticle> _particles;
  final Random _random = Random();

  // 倒计时
  int _countdown = 5;
  Timer? _countdownTimer;

  /// 装饰 emoji 配置
  static const List<String> _decorEmojis = ['🎉', '✨', '🌟', '⭐', '🎊'];

  /// 根据单词数量动态计算每个单词的粒子数
  int get _particlesPerWord {
    final count = widget.words.length;
    // 预留 20% 给装饰粒子
    final maxWordParticles = (widget.particleCount * 0.8).floor();
    final calculated = (maxWordParticles / count).floor();

    // 至少 1 个，最多 6 个
    return calculated.clamp(1, 6);
  }

  /// 根据单词粒子总数计算装饰粒子数量
  int get _decorParticleCount {
    final wordParticleCount = widget.words.length * _particlesPerWord;
    final remaining = widget.particleCount - wordParticleCount;

    // 至少 4 个装饰粒子，最多不超过剩余空间
    return remaining.clamp(4, 12);
  }

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initAnimations();
    _playCelebrationAudio();
    _startCountdown();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _textController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _navigateBack();
      }
    });
  }

  void _navigateBack() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 播放表扬语音
  void _playCelebrationAudio() {
    final player = AudioPlayer();
    player.play(AssetSource('audio/celebrations/well_done.wav'));
  }

  void _initParticles() {
    _particles = [];

    // 1. 生成单词粒子
    for (final word in widget.words) {
      for (var i = 0; i < _particlesPerWord; i++) {
        _particles.add(_createParticle(
          emoji: word.emoji,
          image: word.image,
        ));
      }
    }

    // 2. 生成装饰粒子（使用 emoji）
    for (var i = 0; i < _decorParticleCount; i++) {
      final decorEmoji = _decorEmojis[_random.nextInt(_decorEmojis.length)];
      _particles.add(_createParticle(emoji: decorEmoji, isDecor: true));
    }

    // 3. 打乱顺序
    _particles.shuffle(_random);
  }

  _CelebrationParticle _createParticle({String? emoji, String? image, bool isDecor = false}) {
    final speed = widget.startVelocity * (0.7 + _random.nextDouble() * 0.6);
    final spreadRad = widget.spread * pi / 180; // 度转弧度
    final angle = -pi / 2 + (_random.nextDouble() - 0.5) * spreadRad;
    final scale = isDecor ? 0.4 + _random.nextDouble() * 0.3 : 0.6 + _random.nextDouble() * 0.4;

    return _CelebrationParticle(
      emoji: emoji,
      image: image,
      x: 0.5 + (_random.nextDouble() - 0.5) * 0.08,
      y: 0.9,
      velocityX: speed * cos(angle),
      velocityY: speed * sin(angle),
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.15,
      scale: scale,
    );
  }

  void _initAnimations() {
    // 粒子动画控制器
    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _particleController.addListener(_updateParticles);
    _particleController.forward();

    // 文字弹出动画
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));
    _textController.forward();
  }

  void _updateParticles() {
    setState(() {
      for (final p in _particles) {
        // 1. 应用速度衰减
        p.velocityX *= widget.decay;
        p.velocityY *= widget.decay;

        // 2. 应用重力加速度（缩放到合适的值）
        p.velocityY += widget.gravity * 0.0006;

        // 3. 更新位置
        p.x += p.velocityX;
        p.y += p.velocityY;

        // 4. 更新旋转
        p.rotation += p.rotationSpeed;
        p.rotationSpeed *= widget.decay;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 粒子层
              ..._particles.map((p) => _buildParticle(p, size)),

              // 中央内容
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCelebrationText(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Done 按钮（底部）
              Positioned(
                left: AppTheme.spacingLarge,
                right: AppTheme.spacingLarge,
                bottom: AppTheme.spacingLarge,
                child: _buildDoneButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationText() {
    return AnimatedBuilder(
      animation: _textScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _textScaleAnimation.value,
          child: child,
        );
      },
      child: Text(
        'Well done!',
        style: AppTheme.displayLarge.copyWith(
          fontSize: 48,
          color: AppTheme.primary,
          shadows: [
            Shadow(
              color: AppTheme.primary.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
            Shadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    return GestureDetector(
      onTap: _navigateBack,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2), // 微调视觉位置
              child: Text(
                'Done',
                style: AppTheme.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.0, // 消除默认行高影响
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Container(
              constraints: const BoxConstraints(minWidth: 32),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 增加一点垂直padding
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_countdown',
                textAlign: TextAlign.center,
                style: AppTheme.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.0, // 消除默认行高影响
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle(_CelebrationParticle particle, Size screenSize) {
    if (particle.y > 1.3 || particle.y < -0.3 || particle.x < -0.2 || particle.x > 1.2) {
      return const SizedBox.shrink();
    }

    const size = 48.0;
    final Widget child;

    // 优先使用 image，不存在则用 emoji
    if (particle.image != null && particle.image!.isNotEmpty) {
      // 图片粒子：动态判断网络/本地
      final isNetwork = isNetworkUrl(particle.image!);

      child = isNetwork
          ? Image.network(
              particle.image!,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text('⭐', style: TextStyle(fontSize: size)),
            )
          : Image.asset(
              particle.image!,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text('⭐', style: TextStyle(fontSize: size)),
            );
    } else {
      // Emoji 粒子
      child = Text(
        particle.emoji ?? '⭐',
        style: const TextStyle(fontSize: size),
      );
    }

    return Positioned(
      left: particle.x * screenSize.width - size / 2,
      top: particle.y * screenSize.height - size / 2,
      child: Transform.rotate(
        angle: particle.rotation,
        child: Transform.scale(
          scale: particle.scale,
          child: child,
        ),
      ),
    );
  }
}
