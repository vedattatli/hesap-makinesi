import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hesap_makinesi/main.dart';

void main() {
  testWidgets('calculator evaluates a simple addition',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScientificCalculatorApp());

    for (final label in ['7', '+', '8', '=']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    final resultText = tester.widget<Text>(
      find.byKey(const Key('result-text')),
    );

    expect(resultText.data, '15');
  });
}
