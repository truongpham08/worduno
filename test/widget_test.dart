import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worduno/app/app.dart';
import 'package:worduno/app/di/injection.dart';

void main() {
  setUpAll(() async {
    await setupDependencies();
  });

  testWidgets('app launches with bottom navigation', (tester) async {
    await tester.pumpWidget(const WordunoApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Exam History'), findsOneWidget);
    expect(find.text('Coach History'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs', (tester) async {
    await tester.pumpWidget(const WordunoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('DashboardPage stub'), findsOneWidget);
  });
}
