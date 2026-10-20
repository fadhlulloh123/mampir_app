import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mampir_app/main.dart';

void main() {
  testWidgets('MAMPIR app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MampirApp());
    // Verify the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
