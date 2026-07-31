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
    expect(
      categories.map((category) => category['id']).toList(),
      [
        'animals',
        'foods',
        'body',
        'actions',
        'vehicles',
        'home',
        'colors',
        'clothes',
        'feelings',
        'nature',
        'places',
        'music',
      ],
    );
    expect(
      categories.map((category) => category['id']).toSet(),
      hasLength(categories.length),
      reason: 'Category IDs must be globally unique',
    );
    const expectedWordCounts = {
      'animals': 34,
      'foods': 38,
      'body': 12,
      'actions': 16,
      'vehicles': 17,
      'home': 24,
      'colors': 15,
      'clothes': 11,
      'feelings': 8,
      'nature': 16,
      'places': 23,
      'music': 16,
    };
    final words = <Map<String, dynamic>>[];
    for (final category in categories) {
      final categoryWords =
          (category['words'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(
        categoryWords,
        hasLength(expectedWordCounts[category['id']]!),
        reason: '${category['id']} has an unexpected word count',
      );
      expect(
        categoryWords.length,
        greaterThanOrEqualTo(8),
        reason: '${category['id']} must support an 8-word lesson',
      );
      expect(
        categoryWords.map((word) => word['id']).toSet(),
        hasLength(categoryWords.length),
        reason: '${category['id']} contains duplicate word IDs',
      );
      final image = category['image'] as String?;
      expect(image, isNotNull, reason: '${category['id']} needs a PNG icon');
      expect(
        File('assets/images/categories/$image').existsSync(),
        isTrue,
        reason: 'Missing category image: $image',
      );
      words.addAll(categoryWords);
    }

    expect(words, hasLength(230));
    expect(
      categories.any((category) => category['id'] == 'jobs'),
      isFalse,
      reason: 'Jobs was merged into Places & People',
    );
    for (final legacyId in ['headphone', 'brush', 'wash', 'stone']) {
      expect(
        words.any((word) => word['id'] == legacyId),
        isFalse,
        reason: 'Legacy word ID still configured: $legacyId',
      );
    }
    final colors =
        categories.singleWhere((category) => category['id'] == 'colors');
    final colorOrange = (colors['words'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .singleWhere((word) => word['id'] == 'orange');
    expect(colorOrange['nameZh'], '橙色');
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
