import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/app/app.dart';
import 'package:worduno/app/di/injection.dart';
import 'package:worduno/features/dashboard/application/services/i_dashboard_service.dart';
import 'package:worduno/shared/vocabulary/application/services/i_vocabulary_service.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app_setup.dart';

void main() {
  setUpAll(() async {
    await setupWordunoTestDependencies();
    await getIt.unregister<IVocabularyService>();
    await getIt.unregister<IDashboardService>();
    getIt.registerLazySingleton<IVocabularyService>(
      () => FakeVocabularyService(),
    );
    getIt.registerLazySingleton<IDashboardService>(FakeDashboardService.new);
  });

  testWidgets('app launches with bottom navigation', (tester) async {
    await tester.pumpWidget(const WordunoApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Your Levels'), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs', (tester) async {
    await tester.pumpWidget(const WordunoApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Stats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('OVERALL PROGRESS'), findsOneWidget);
  });
}
