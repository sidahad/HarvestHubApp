import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:harvesthub_app/main.dart';

void main() {
  testWidgets('starts with splash and loads app', (WidgetTester tester) async {
    await tester.pumpWidget(const HarvestHubApp());
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
