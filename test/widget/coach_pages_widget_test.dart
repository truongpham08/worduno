import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/app/di/injection.dart';
import 'package:worduno/features/coach/application/services/i_coach_service.dart';
import 'package:worduno/features/coach/presentation/views/coach_history_page.dart';
import 'package:worduno/features/coach/presentation/views/coach_session_page.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app_setup.dart';
import '../helpers/widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCoachService fakeCoach;

  setUpAll(() async {
    await setupWordunoTestDependencies();
  });

  setUp(() async {
    fakeCoach = FakeCoachService();

    if (getIt.isRegistered<ICoachService>()) {
      await getIt.unregister<ICoachService>();
    }
    getIt.registerLazySingleton<ICoachService>(() => fakeCoach);
  });

  group('Coach pages widget tests', () {
    testWidgets('CoachSessionPage runs explain → write → feedback phases', (
      tester,
    ) async {
      fakeCoach.seedSession(sampleCoachSession());
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapWithNavigation(const CoachSessionPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('I understand'), findsOneWidget);
      expect(find.text('Common greeting'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('I understand'),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('I understand'));
      await tester.pump();

      expect(find.text('Get AI Feedback'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Hello world');
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Get AI Feedback'),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Get AI Feedback'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('Good'), findsWidgets);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('CoachHistoryPage delete removes coached term', (tester) async {
      fakeCoach.coachedTerms = [sampleCoachHistoryTerm()];

      await tester.pumpWidget(wrapWithNavigation(const CoachHistoryPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('hello'), findsOneWidget);
      expect(find.text('B1 · Travel'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Delete all feedback?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('hello'), findsNothing);
      expect(fakeCoach.coachedTerms, isEmpty);
    });
  });
}
