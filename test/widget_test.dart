import 'package:cross_platform_whiteboard/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('application shows its platform entry screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WhiteboardApp());
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Wireless Stylus Pad'), findsOneWidget);
  });
}
