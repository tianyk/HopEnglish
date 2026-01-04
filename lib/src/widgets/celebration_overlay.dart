import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/theme/app_theme.dart';

/// 庆祝撒花动画粒子数据
class _CelebrationParticle {
  final String emoji;
  double x;
  double y;
  double velocityX;
  double velocityY;
  double rotation;
  double rotationSpeed;
  final double scale;

  _CelebrationParticle({
    required this.emoji,
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.scale,
  });
}

/// 庆祝撒花覆盖层
///
/// 学习完成时展示：从底部喷射单词 emoji + 装饰 emoji，形成扇形后散落
/// 配合语音表扬（随机播放 great/well_done/good_job/awesome/yay）
class CelebrationOverlay extends StatefulWidget {
  final List<Word> words;
  final VoidCallback onComplete;
  final Duration duration;

  const CelebrationOverlay({
    required this.words,
    required this.onComplete,
    this.duration = const Duration(seconds: 4),
    super.key,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_CelebrationParticle> _particles;
  final Random _random = Random();

  /// 装饰 emoji 配置
  static const List<String> _decorEmojis = ['🎉', '✨', '🌟', '⭐', '🎊'];
  static const int _decorParticleCount = 12;

  /// 表扬语音列表
  static const List<String> _celebrationAudios = [
    // 'great',
    'well_done',
    // 'good_job',
    // 'awesome',
    // 'yay',
  ];

  /// 物理参数
  static const double _gravity = 0.0006;
  static const double _drag = 0.012;
  static const double _startVelocity = 0.035;
  static const double _spreadAngle = pi * 0.5;

  /// 根据单词数量动态计算每个单词的粒子数
  int get _particlesPerWord {
    final count = widget.words.length;
    if (count <= 4) return 6;
    if (count <= 7) return 5;
    if (count <= 12) return 3;
    return 2;
  }

  @override
  void initState() {
    super.initState();
    _initParticles();
    _initAnimation();
    _playCelebrationAudio();
  }

  /// 随机播放一个表扬语音
  void _playCelebrationAudio() {
    final audioFile = _celebrationAudios[_random.nextInt(_celebrationAudios.length)];
    final audioPath = 'audio/celebrations/$audioFile.wav';
    final player = AudioPlayer();
    player.play(AssetSource(audioPath));
  }

  void _initParticles() {
    _particles = [];

    // 1. 生成单词粒子
    for (final word in widget.words) {
      final emoji = word.emoji ?? '⭐';
      for (var i = 0; i < _particlesPerWord; i++) {
        _particles.add(_createParticle(emoji));
      }
    }

    // 2. 生成装饰粒子
    for (var i = 0; i < _decorParticleCount; i++) {
      final decorEmoji = _decorEmojis[_random.nextInt(_decorEmojis.length)];
      _particles.add(_createParticle(decorEmoji, isDecor: true));
    }

    // 3. 打乱顺序
    _particles.shuffle(_random);
  }

  _CelebrationParticle _createParticle(String emoji, {bool isDecor = false}) {
    final speed = _startVelocity * (0.7 + _random.nextDouble() * 0.6);
    final angle = -pi / 2 + (_random.nextDouble() - 0.5) * _spreadAngle;
    final scale = isDecor ? 0.4 + _random.nextDouble() * 0.3 : 0.6 + _random.nextDouble() * 0.4;

    return _CelebrationParticle(
      emoji: emoji,
      x: 0.5 + (_random.nextDouble() - 0.5) * 0.08,
      y: 0.9,
      velocityX: speed * cos(angle),
      velocityY: speed * sin(angle),
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.15,
      scale: scale,
    );
  }

  void _initAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.addListener(_updateParticles);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
    _controller.forward();
  }

  void _updateParticles() {
    setState(() {
      for (final p in _particles) {
        // 1. 应用空气阻力
        p.velocityX *= (1 - _drag);
        p.velocityY *= (1 - _drag);

        // 2. 应用恒定重力
        p.velocityY += _gravity;

        // 3. 更新位置
        p.x += p.velocityX;
        p.y += p.velocityY;

        // 4. 更新旋转
        p.rotation += p.rotationSpeed;
        p.rotationSpeed *= (1 - _drag);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _opacity {
    final progress = _controller.value;
    if (progress > 0.75) {
      return (1.0 - progress) / 0.25;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity,
            child: SizedBox.expand(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 半透明背景
                  Positioned.fill(
                    child: Container(
                      color: AppTheme.background.withValues(alpha: 0.3),
                    ),
                  ),
                  // 粒子
                  ..._particles.map((p) => _buildParticle(p, size)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(_CelebrationParticle particle, Size screenSize) {
    if (particle.y > 1.3 || particle.y < -0.3 || particle.x < -0.2 || particle.x > 1.2) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: particle.x * screenSize.width - 24,
      top: particle.y * screenSize.height - 24,
      child: Transform.rotate(
        angle: particle.rotation,
        child: Transform.scale(
          scale: particle.scale,
          child: Text(
            particle.emoji,
            style: const TextStyle(fontSize: 48),
          ),
        ),
      ),
    );
  }
}
