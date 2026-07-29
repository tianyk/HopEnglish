import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:hopenglish/src/models/word.dart';

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
  final AudioPlayer _player;
  final Random _random;
  int _playbackToken = 0;

  AudioPlaybackService({
    AudioPlayer? player,
    Random? random,
  })  : _player = player ?? AudioPlayer(),
        _random = random ?? Random();

  @override
  Future<bool> playWord(
    Word word, {
    bool slow = false,
    bool waitForCompletion = true,
  }) async {
    final token = ++_playbackToken;
    final fallbackTimer = Stopwatch()..start();
    try {
      await _player.stop();
      final assetPath = _assetPath(word, slow: slow);
      final completion = _player.onPlayerComplete.first;
      if (word.isAudioNetwork && !slow) {
        await _player.play(UrlSource(word.audioPath));
      } else {
        await _player.play(AssetSource(assetPath));
      }
      if (!waitForCompletion) return true;
      await completion.timeout(const Duration(seconds: 4));
      return token == _playbackToken;
    } catch (_) {
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
    const files = ['awesome.wav', 'good_job.wav', 'great.wav', 'yay.wav'];
    await _playCelebration(files[_random.nextInt(files.length)]);
  }

  @override
  Future<void> playCompletion() async {
    const files = [
      'awesome.wav',
      'good_job.wav',
      'great.wav',
      'well_done.wav',
      'yay.wav',
    ];
    await _playCelebration(files[_random.nextInt(files.length)]);
  }

  Future<void> _playCelebration(String filename) async {
    ++_playbackToken;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/celebrations/$filename'));
    } catch (_) {
      // Audio feedback must never block the lesson.
    }
  }

  String _assetPath(Word word, {required bool slow}) {
    final normal = word.audioPath.replaceFirst('assets/', '');
    if (!slow || word.isAudioNetwork) return normal;
    return normal.replaceFirst(RegExp(r'_normal\.wav$'), '_slow.wav');
  }

  @override
  Future<void> stop() async {
    ++_playbackToken;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    ++_playbackToken;
    await _player.dispose();
  }
}
