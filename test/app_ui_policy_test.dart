import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopenglish/main.dart';
import 'package:hopenglish/src/widgets/lesson_settings_sheet.dart';

void main() {
  testWidgets('app content always uses a fixed 1.0 text scale', (tester) async {
    late double effectiveScale;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3.2)),
        child: AppTextScaleBoundary(
          child: Builder(
            builder: (context) {
              effectiveScale = MediaQuery.textScalerOf(context).scale(1);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(effectiveScale, 1);
  });

  testWidgets('lesson settings use parent-facing Chinese copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonSettingsSheet(
            selectedCount: 6,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('每课学习几个单词'), findsOneWidget);
    expect(find.text('选择适合孩子的学习节奏'), findsOneWidget);
    expect(find.text('个单词'), findsNWidgets(3));
    expect(find.text('约 3 分钟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
