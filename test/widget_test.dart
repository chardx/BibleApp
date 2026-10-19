import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_app/main.dart';

void main() {
  testWidgets('ScriptureLiveApp initial smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScriptureLiveApp());
    await tester.pump();

    // Verify Title & mic icon exists
    expect(find.text('SCRIPTURE LIVE'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsWidgets);
  });
}
