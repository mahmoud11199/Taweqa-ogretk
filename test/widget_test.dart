import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taweqa_ogretk/app.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const TaweqeApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
