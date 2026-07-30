import 'package:flutter_test/flutter_test.dart';
import 'package:hopenglish/src/services/audio_playback_service.dart';

void main() {
  test('encouragement and completion use separate weighted audio pools', () {
    expect(
      AudioPlaybackService.encouragementWeights,
      const {
        'great.wav': 7,
        'good_job.wav': 3,
      },
    );
    expect(
      AudioPlaybackService.completionWeights,
      const {
        'well_done.wav': 7,
        'yay.wav': 3,
      },
    );
    expect(
      AudioPlaybackService.encouragementWeights,
      isNot(contains('awesome.wav')),
    );
    expect(
      AudioPlaybackService.completionWeights,
      isNot(contains('awesome.wav')),
    );
  });
}
