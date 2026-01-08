import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cicd_frontend/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is present
    expect(find.text('CI/CD Platform Dashboard'), findsOneWidget);
  });

  testWidgets('Refresh button is present', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // The refresh button should be present
    expect(find.widgetWithIcon(ElevatedButton, Icons.refresh), findsWidgets);
  });
}
