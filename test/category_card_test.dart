import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
import 'package:hopenglish/src/widgets/category_card.dart';

void main() {
  testWidgets('category card prefers its stable image asset', (tester) async {
    const category = Category(
      id: 'animals',
      emoji: 'fallback',
      image: 'animals.png',
      name: 'Animals',
      color: Colors.orange,
      words: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 240,
          height: 240,
          child: CategoryCard(category: category),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('fallback'), findsNothing);
    expect(find.text('Animals'), findsOneWidget);

    final decoratedCard = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((decoration) => decoration.border != null);
    final border = decoratedCard.border! as Border;
    expect(border.top.color, AppTheme.cardBorder);
  });
}
