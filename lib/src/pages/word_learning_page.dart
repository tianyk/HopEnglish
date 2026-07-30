import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hopenglish/src/learning/learning_engine.dart';
import 'package:hopenglish/src/learning/learning_models.dart';
import 'package:hopenglish/src/learning/learning_policy.dart';
import 'package:hopenglish/src/models/lesson_plan.dart';
import 'package:hopenglish/src/models/word.dart';
import 'package:hopenglish/src/pages/celebration_page.dart';
import 'package:hopenglish/src/services/audio_playback_service.dart';
import 'package:hopenglish/src/services/learning_progress_service.dart';
import 'package:hopenglish/src/services/lesson_quiz_controller.dart';
import 'package:hopenglish/src/services/lesson_session_service.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/widgets/adaptive_image.dart';
import 'package:hopenglish/src/widgets/word_icon.dart';

enum _LessonPhase { learn, quiz }

typedef AttemptRecorder = Future<LearningTransition> Function({
  required LessonQuestion question,
  required bool firstAttemptCorrect,
});

class WordLearningPage extends StatefulWidget {
  final LessonPlan plan;
  final int lessonSize;
  final AudioPlaybackController? audio;
  final AttemptRecorder? attemptRecorder;

  const WordLearningPage({
    required this.plan,
    required this.lessonSize,
    this.audio,
    this.attemptRecorder,
    super.key,
  });

  @override
  State<WordLearningPage> createState() => _WordLearningPageState();
}

class _WordLearningPageState extends State<WordLearningPage>
    with TickerProviderStateMixin {
  static const Duration _effectiveViewDelay = Duration(milliseconds: 1200);
  static const Duration _finalAnswerAdvanceDelay = Duration(milliseconds: 400);

  final LearningProgressService _progress = LearningProgressService.instance;
  late final AudioPlaybackController _audio;
  late final bool _ownsAudio;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  _LessonPhase _phase = _LessonPhase.learn;
  late final List<Word> _studyWords;
  late final LessonQuizController _quizController;
  int _learnIndex = 0;
  int _quizIndex = 0;
  bool _canContinue = false;
  bool _answerLocked = false;
  bool _firstAttemptPending = true;
  String? _wrongOptionId;
  String? _correctOptionId;
  Timer? _effectiveViewTimer;
  Timer? _manualPlaybackCooldownTimer;
  int _presentationToken = 0;
  double _displayedProgress = 0;

  @override
  void initState() {
    super.initState();
    _ownsAudio = widget.audio == null;
    _audio = widget.audio ?? AudioPlaybackService();
    _studyWords = List.of(widget.plan.studyWords);
    _quizController = LessonQuizController(
      policy: LearningPolicyRegistry.forVersion(widget.plan.policyVersion),
      randomSeed: widget.plan.randomSeed,
      lessonId: widget.plan.lessonId,
      categoryWords: widget.plan.category.words,
      initialQuestions: widget.plan.questions,
    );
    _phase = _studyWords.isEmpty ? _LessonPhase.quiz : _LessonPhase.learn;
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.92), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1), weight: 1),
    ]).animate(_bounceController);
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progress.touchCategorySession(categoryId: widget.plan.category.id);
      if (_phase == _LessonPhase.learn) {
        _presentLearningWord();
      } else if (_questions.isNotEmpty) {
        _playCurrentWord(slow: false);
      }
    });
  }

  Word get _currentWord => _studyWords[_learnIndex];
  List<LessonQuestion> get _questions => _quizController.questions;
  LessonQuestion get _currentQuestion => _questions[_quizIndex];

  int get _totalSteps => _studyWords.length + _questions.length;
  int get _completedSteps => _phase == _LessonPhase.learn
      ? _learnIndex
      : _studyWords.length + _quizIndex;

  @override
  void dispose() {
    _effectiveViewTimer?.cancel();
    _manualPlaybackCooldownTimer?.cancel();
    _progress.saveCategoryExitedAt(categoryId: widget.plan.category.id);
    if (_ownsAudio) unawaited(_audio.dispose());
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _presentLearningWord() async {
    final token = ++_presentationToken;
    _effectiveViewTimer?.cancel();
    _manualPlaybackCooldownTimer?.cancel();
    setState(() => _canContinue = false);
    _effectiveViewTimer = Timer(_effectiveViewDelay, () {
      if (!mounted ||
          token != _presentationToken ||
          _phase != _LessonPhase.learn) {
        return;
      }
      _progress.recordEffectiveView(
        category: widget.plan.category,
        word: _currentWord,
      );
    });
    await _playCurrentWord(slow: false, lockContinue: true, token: token);
  }

  Future<void> _playCurrentWord({
    required bool slow,
    bool lockContinue = false,
    int? token,
  }) async {
    if (lockContinue && mounted) setState(() => _canContinue = false);
    _bounceController.forward(from: 0);
    final word =
        _phase == _LessonPhase.learn ? _currentWord : _currentQuestion.target;
    final played = await _audio.playWord(
      word,
      slow: slow,
      waitForCompletion: lockContinue,
    );
    if (played && mounted) {
      _progress.recordSuccessfulPlay(
        category: widget.plan.category,
        word: word,
      );
    }
    if (lockContinue &&
        mounted &&
        (token == null || token == _presentationToken) &&
        _phase == _LessonPhase.learn) {
      setState(() => _canContinue = true);
    }
  }

  void _playManually({required bool slow}) {
    if (_phase != _LessonPhase.learn ||
        (_manualPlaybackCooldownTimer?.isActive ?? false)) {
      return;
    }
    _manualPlaybackCooldownTimer = Timer(AppTheme.buttonCooldown, () {});
    final completesInitialListen = !_canContinue;
    unawaited(
      _playCurrentWord(
        slow: slow,
        lockContinue: completesInitialListen,
        token: completesInitialListen ? _presentationToken : null,
      ),
    );
  }

  Future<void> _nextLearningWord() async {
    if (!_canContinue) return;
    if (_learnIndex + 1 < _studyWords.length) {
      setState(() => _learnIndex++);
      await _presentLearningWord();
      return;
    }
    _effectiveViewTimer?.cancel();
    ++_presentationToken;
    setState(() {
      _phase = _LessonPhase.quiz;
      _quizIndex = 0;
      _canContinue = false;
    });
    await _playCurrentWord(slow: false);
  }

  Future<void> _selectAnswer(Word selected) async {
    if (_answerLocked || _correctOptionId != null) return;
    _answerLocked = true;
    final isCorrect = selected.id == _currentQuestion.target.id;
    final practiceOnly = _currentQuestion.kind == QuestionKind.errorRetry ||
        _currentQuestion.kind == QuestionKind.reinforcementRetrieval;
    if (!isCorrect) {
      setState(() => _wrongOptionId = selected.id);
      await _shakeController.forward(from: 0);
      if (!mounted) return;
      LearningTransition? transition;
      if (_firstAttemptPending) {
        if (!practiceOnly) {
          transition = await _recordAttempt(
            question: _currentQuestion,
            firstAttemptCorrect: false,
          );
          if (!mounted || transition == null) {
            if (mounted) {
              setState(() {
                _answerLocked = false;
                _wrongOptionId = null;
              });
            }
            return;
          }
        }
        _firstAttemptPending = false;
        _scheduleRetry(_currentQuestion, transition);
      }
      setState(() {
        _wrongOptionId = null;
        _answerLocked = false;
      });
      await _playCurrentWord(slow: false);
      return;
    }

    if (_firstAttemptPending && !practiceOnly) {
      final transition = await _recordAttempt(
        question: _currentQuestion,
        firstAttemptCorrect: true,
      );
      if (!mounted || transition == null) {
        if (mounted) setState(() => _answerLocked = false);
        return;
      }
    }
    _firstAttemptPending = false;
    setState(() => _correctOptionId = selected.id);
    final isLastQuestion = _quizIndex + 1 >= _questions.length;
    if (isLastQuestion) {
      await Future<void>.delayed(_finalAnswerAdvanceDelay);
    } else {
      await _audio.playEncouragement();
    }
    if (!mounted) return;
    await _advanceQuiz();
  }

  Future<LearningTransition?> _recordAttempt({
    required LessonQuestion question,
    required bool firstAttemptCorrect,
  }) async {
    try {
      final recorder = widget.attemptRecorder;
      if (recorder != null) {
        return await recorder(
          question: question,
          firstAttemptCorrect: firstAttemptCorrect,
        );
      }
      if (widget.plan.lessonId == 'legacy') {
        _progress.recordQuizResult(
          category: widget.plan.category,
          word: question.target,
          firstAttemptCorrect: firstAttemptCorrect,
        );
        return LearningEngine(
          LearningPolicyRegistry.forVersion(widget.plan.policyVersion),
        ).applyAttempt(AttemptInput(
          currentStage: question.stage,
          currentReviewLevel: question.reviewLevel,
          lessonId: widget.plan.lessonId,
          lastQuizLessonId: question.lastQuizLessonId,
          questionKind: question.kind,
          firstAttemptCorrect: firstAttemptCorrect,
          nowMs: DateTime.now().millisecondsSinceEpoch,
        ));
      }
      return await _progress.recordLearningAttempt(
        category: widget.plan.category,
        question: question,
        lessonId: widget.plan.lessonId,
        policyVersion: widget.plan.policyVersion,
        firstAttemptCorrect: firstAttemptCorrect,
      );
    } catch (_) {
      return null;
    }
  }

  void _scheduleRetry(
    LessonQuestion question,
    LearningTransition? transition,
  ) {
    _quizController.scheduleRetry(
      currentIndex: _quizIndex,
      question: question,
      transition: transition,
    );
  }

  Future<void> _advanceQuiz() async {
    if (_quizIndex + 1 < _questions.length) {
      setState(() {
        _quizIndex++;
        _answerLocked = false;
        _firstAttemptPending = true;
        _wrongOptionId = null;
        _correctOptionId = null;
      });
      await _playCurrentWord(slow: false);
    } else {
      await _openCelebration();
    }
  }

  Future<void> _openCelebration() async {
    await _audio.stop();
    if (!mounted) return;
    final completedIds = widget.plan.words.map((word) => word.id).toSet();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CelebrationPage(
          words: widget.plan.words,
          themeColor: widget.plan.category.color,
          onHome: (pageContext) {
            Navigator.of(pageContext).popUntil((route) => route.isFirst);
          },
          onMore: (pageContext) async {
            final nextPlan = await LessonSessionService.instance.buildLesson(
              category: widget.plan.category,
              lessonSize: widget.lessonSize,
              excludeWordIds: completedIds,
            );
            if (!pageContext.mounted) return;
            Navigator.of(pageContext).pushReplacement(
              MaterialPageRoute(
                builder: (_) => WordLearningPage(
                  plan: nextPlan,
                  lessonSize: widget.lessonSize,
                ),
              ),
            );
          },
        ),
      ),
    );
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
              _buildProgress(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppTheme.durationNormal,
                  child: _phase == _LessonPhase.learn
                      ? _buildLearningView()
                      : _buildQuizView(),
                ),
              ),
              if (_phase == _LessonPhase.learn) _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final category = widget.plan.category;
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
              errorWidget: Text(category.emoji ?? '',
                  style: const TextStyle(fontSize: 28)),
            )
          else
            Text(category.emoji ?? '', style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _phase == _LessonPhase.learn ? category.name : 'Listen & Find',
              style: AppTheme.headlineMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final rawValue =
        _totalSteps == 0 ? 1.0 : (_completedSteps + 1) / _totalSteps;
    _displayedProgress = math.max(_displayedProgress, rawValue);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          minHeight: 10,
          value: _displayedProgress.clamp(0, 1),
          backgroundColor: AppTheme.backgroundWarm,
          color: widget.plan.category.color,
        ),
      ),
    );
  }

  Widget _buildLearningView() {
    return LayoutBuilder(
      key: ValueKey('learn-${_currentWord.id}'),
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 480;
        final iconSize = compact ? 135.0 : 190.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              key: const ValueKey('learning-image'),
              onTap: () => _playManually(slow: false),
              child: ScaleTransition(
                scale: _bounceAnimation,
                child: WordIcon(word: _currentWord, size: iconSize),
              ),
            ),
            SizedBox(height: compact ? 12 : 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                child: Text(
                  _currentWord.name,
                  style:
                      AppTheme.displayLarge.copyWith(color: AppTheme.primary),
                  maxLines: 1,
                ),
              ),
            ),
            SizedBox(height: compact ? 14 : 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _audioButton(
                  key: const ValueKey('listen-normal'),
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: AppTheme.primary,
                    size: 30,
                  ),
                  label: 'Listen',
                  onTap: () => _playManually(slow: false),
                ),
                const SizedBox(width: 16),
                _audioButton(
                  key: const ValueKey('listen-slow'),
                  icon: SvgPicture.asset(
                    'assets/images/icons/solid-slow.svg',
                    width: 24,
                    height: 19,
                    colorFilter: const ColorFilter.mode(
                      AppTheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Slow',
                  onTap: () => _playManually(slow: true),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuizView() {
    final options = _currentQuestion.options;
    if (options.length == 2) return _buildTwoChoiceQuiz(options);

    return Column(
      key: ValueKey('quiz-${_currentQuestion.target.id}'),
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _playCurrentWord(slow: false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: const Icon(Icons.volume_up_rounded,
                color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Text('Tap the picture', style: AppTheme.titleMedium),
        const SizedBox(height: 28),
        Expanded(
          child: _buildFourChoiceLayout(options),
        ),
      ],
    );
  }

  Widget _buildTwoChoiceQuiz(List<Word> options) {
    return LayoutBuilder(
      key: ValueKey('quiz-${_currentQuestion.target.id}'),
      builder: (context, constraints) {
        const gap = 16.0;
        final usableWidth = math.min(constraints.maxWidth - 48, 360.0);
        final cardWidth = (usableWidth - gap) / 2;
        final desiredHeight = cardWidth / 0.86;
        final cardHeight = math.min(
          desiredHeight,
          math.max(120.0, constraints.maxHeight - 160),
        );
        return Align(
          alignment: const Alignment(0, -0.15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _playCurrentWord(slow: false),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Tap the picture', style: AppTheme.titleMedium),
              const SizedBox(height: 44),
              SizedBox(
                key: const ValueKey('two-choice-layout'),
                width: usableWidth,
                height: cardHeight,
                child: Row(
                  children: [
                    for (var index = 0; index < options.length; index++) ...[
                      if (index > 0) const SizedBox(width: gap),
                      Expanded(child: _buildAnswerCard(options[index])),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFourChoiceLayout(List<Word> options) {
    return LayoutBuilder(
      key: const ValueKey('four-choice-layout'),
      builder: (context, constraints) {
        const gap = 16.0;
        final maxCardWidth = (constraints.maxWidth - 48 - gap) / 2;
        final maxCardHeight = (constraints.maxHeight - 24 - gap) / 2;
        final cardSize = math.max(
          0.0,
          math.min(maxCardWidth, maxCardHeight),
        );
        return Center(
          child: SizedBox(
            width: cardSize * 2 + gap,
            height: cardSize * 2 + gap,
            child: Column(
              children: [
                for (var row = 0; row < 2; row++) ...[
                  if (row > 0) const SizedBox(height: gap),
                  SizedBox(
                    height: cardSize,
                    child: Row(
                      children: [
                        for (var column = 0; column < 2; column++) ...[
                          if (column > 0) const SizedBox(width: gap),
                          SizedBox(
                            width: cardSize,
                            child: _buildAnswerCard(
                              options[row * 2 + column],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerCard(Word word) {
    final isCorrect = _correctOptionId == word.id;
    final isWrong = _wrongOptionId == word.id;
    Widget card = GestureDetector(
      key: ValueKey('answer-${word.id}'),
      onTap: () => _selectAnswer(word),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isCorrect
                ? AppTheme.success
                : widget.plan.category.color.withValues(alpha: 0.28),
            width: isCorrect ? 5 : 2,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final iconSize = math
                      .min(constraints.maxWidth, constraints.maxHeight)
                      .clamp(72.0, 124.0);
                  return Center(child: WordIcon(word: word, size: iconSize));
                },
              ),
            ),
            if (isCorrect)
              const Positioned(
                top: 10,
                right: 12,
                child:
                    Icon(Icons.star_rounded, color: AppTheme.success, size: 34),
              ),
          ],
        ),
      ),
    );
    if (isWrong) {
      card = AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        ),
        child: card,
      );
    }
    return card;
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GestureDetector(
        key: const ValueKey('lesson-next'),
        onTap: _canContinue ? _nextLearningWord : null,
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 19),
          decoration: BoxDecoration(
            color: _canContinue
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: _canContinue ? AppTheme.buttonShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _learnIndex + 1 == _studyWords.length ? 'Practice' : 'Next',
                style: AppTheme.headlineMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _audioButton({
    Key? key,
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 112,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.35), width: 2),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 30,
              child: Center(child: icon),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.titleMedium),
          ],
        ),
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
}
