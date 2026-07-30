import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:hopenglish/src/libs/logger.dart';
import 'package:hopenglish/src/models/word.dart';

final _logger = Logger.getLogger();

abstract class AudioPlaybackController {
  Future<bool> playWord(
    Word word, {
    bool slow = false,
    bool waitForCompletion = true,
  });

  Future<void> playEncouragement();

  Future<void> playCompletion();

  Future<void> stop();

  Future<void> dispose();
}

class AudioPlaybackService implements AudioPlaybackController {
  static const Map<String, int> encouragementWeights = {
    'great.wav': 7,
    'good_job.wav': 3,
  };
  static const Map<String, int> completionWeights = {
    'well_done.wav': 7,
    'yay.wav': 3,
  };

  final AudioPlayer _player;
  final Random _random;
  late final Future<void> _ready;
  int _playbackToken = 0;

  AudioPlaybackService({
    AudioPlayer? player,
    Random? random,
  })  : _player = player ?? AudioPlayer(),
        _random = random ?? Random() {
    _ready = _player.setReleaseMode(ReleaseMode.stop);
  }

  @override
  Future<bool> playWord(
    Word word, {
    bool slow = false,
    bool waitForCompletion = true,
  }) async {
    final token = ++_playbackToken;
    final fallbackTimer = Stopwatch()..start();
    final assetPath = _assetPath(word, slow: slow);
    try {
      await _ready;
      await _player.stop();
      final completion =
          waitForCompletion ? _player.onPlayerComplete.first : null;
      if (word.isAudioNetwork && !slow) {
        await _player.play(UrlSource(word.audioPath));
      } else {
        await _player.play(AssetSource(assetPath));
      }
      if (completion == null) return token == _playbackToken;
      await completion.timeout(const Duration(seconds: 4));
      return token == _playbackToken;
    } catch (error, stackTrace) {
      _logger.error(
        'playWord failed',
        error: error,
        stackTrace: stackTrace,
        data: {
          'wordId': word.id,
          'assetPath': assetPath,
          'slow': slow,
          'playerState': _player.state.name,
        },
      );
      if (waitForCompletion) {
        const fallbackDelay = Duration(milliseconds: 1200);
        final remaining = fallbackDelay - fallbackTimer.elapsed;
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
      return false;
    }
  }

  @override
  Future<void> playEncouragement() async {
    await _playCelebration(_selectWeighted(encouragementWeights));
  }

  @override
  Future<void> playCompletion() async {
    await _playCelebration(_selectWeighted(completionWeights));
  }

  Future<void> _playCelebration(String filename) async {
    final token = ++_playbackToken;
    try {
      await _ready;
      await _player.stop();
      final completion = _player.onPlayerComplete.first;
      await _player.play(AssetSource('audio/celebrations/$filename'));
      await completion.timeout(const Duration(seconds: 3));
      if (token != _playbackToken) return;
    } catch (error, stackTrace) {
      _logger.error(
        'feedback playback failed',
        error: error,
        stackTrace: stackTrace,
        data: {
          'filename': filename,
          'playerState': _player.state.name,
        },
      );
    }
  }

  String _selectWeighted(Map<String, int> weights) {
    final totalWeight =
        weights.values.fold<int>(0, (sum, value) => sum + value);
    var selection = _random.nextInt(totalWeight);
    for (final entry in weights.entries) {
      selection -= entry.value;
      if (selection < 0) return entry.key;
    }
    return weights.keys.last;
  }

  String _assetPath(Word word, {required bool slow}) {
    final normal = word.audioPath.replaceFirst('assets/', '');
    if (!slow || word.isAudioNetwork) return normal;
    return normal.replaceFirst(RegExp(r'_normal\.wav$'), '_slow.wav');
  }

  @override
  Future<void> stop() async {
    ++_playbackToken;
    await _ready;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    ++_playbackToken;
    try {
      await _ready;
    } catch (_) {
      // Dispose the player even if its initial configuration failed.
    }
    await _player.dispose();
  }
}
