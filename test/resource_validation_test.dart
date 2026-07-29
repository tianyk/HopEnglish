import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all configured category, word image, and audio assets exist', () {
    final categories = (jsonDecode(
      File('assets/data/categories.json').readAsStringSync(),
    ) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(categories, hasLength(12));
    final words = <Map<String, dynamic>>[];
    for (final category in categories) {
      final image = category['image'] as String?;
      expect(image, isNotNull, reason: '${category['id']} needs a PNG icon');
      expect(
        File('assets/images/categories/$image').existsSync(),
        isTrue,
        reason: 'Missing category image: $image',
      );
      words.addAll(
        (category['words'] as List<dynamic>).cast<Map<String, dynamic>>(),
      );
    }

    expect(words, hasLength(211));
    for (final word in words) {
      final image = word['image'] as String;
      final normalAudio = word['audio'] as String;
      final slowAudio =
          normalAudio.replaceFirst(RegExp(r'_normal\.wav$'), '_slow.wav');
      expect(
        File('assets/images/words/$image').existsSync(),
        isTrue,
        reason: 'Missing word image: $image',
      );
      expect(
        File('assets/audio/words/$normalAudio').existsSync(),
        isTrue,
        reason: 'Missing normal audio: $normalAudio',
      );
      expect(
        File('assets/audio/words/$slowAudio').existsSync(),
        isTrue,
        reason: 'Missing slow audio: $slowAudio',
      );
    }

    for (final name in [
      'awesome',
      'good_job',
      'great',
      'well_done',
      'yay',
    ]) {
      expect(
        File('assets/audio/celebrations/$name.wav').existsSync(),
        isTrue,
        reason: 'Missing celebration audio: $name.wav',
      );
    }
  });
}
