import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/app/di/injection.dart';
import 'package:worduno/app/navigation/app_navigation_notifier.dart';
import 'package:worduno/app/routes/route_paths.dart';
import 'package:worduno/features/exam/application/services/i_exam_service.dart';
import 'package:worduno/features/exam/domain/entities/exam_history.dart';
import 'package:worduno/features/exam/presentation/views/exam_pages.dart';
import 'package:worduno/shared/vocabulary/application/services/i_vocabulary_service.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app_setup.dart';
import '../helpers/widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeExamService fakeExam;

  setUpAll(() async {
    await setupWordunoTestDependencies();
  });

  setUp(() async {
    fakeExam = FakeExamService();

    if (getIt.isRegistered<IExamService>()) {
      await getIt.unregister<IExamService>();
    }
    if (getIt.isRegistered<IVocabularyService>()) {
      await getIt.unregister<IVocabularyService>();
    }

    getIt.registerLazySingleton<IExamService>(() => fakeExam);
    getIt.registerLazySingleton<IVocabularyService>(FakeVocabularyService.new);
  });

  group('Exam pages widget tests', () {
    testWidgets('ExamSessionPage shows questions and submit button', (tester) async {
      fakeExam.seedPaper(sampleExamPaper());

      await tester.pumpWidget(wrapWithNavigation(const ExamSessionPage()));
      await tester.pump();

      expect(find.text('Submit Exam'), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('Term → Definition'), findsOneWidget);
    });

    testWidgets('ExamSessionPage submit navigates to result route', (tester) async {
      fakeExam.seedPaper(sampleExamPaper());
      final nav = AppNavigationNotifier();

      await tester.pumpWidget(
        wrapWithNavigation(const ExamSessionPage(), notifier: nav),
      );
      await tester.pump();

      await tester.tap(find.text('Submit Exam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeExam.currentResult, isNotNull);
      expect(
        nav.configuration.homeStack.last.path,
        HomeRoutePaths.examResult,
      );
    });

    testWidgets('ExamResultPage toggles review mode', (tester) async {
      fakeExam.seedResult(sampleExamResult());

      await tester.pumpWidget(wrapWithNavigation(const ExamResultPage()));
      await tester.pump();

      expect(find.text('Review Answers'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      await tester.tap(find.text('Review Answers'));
      await tester.pump();

      expect(find.text('Back to summary'), findsOneWidget);
      expect(find.text('Your answer: greeting'), findsOneWidget);

      await tester.tap(find.text('Back to summary'));
      await tester.pump();

      expect(find.text('Review Answers'), findsOneWidget);
    });

    testWidgets('ExamHistoryPage lists saved exams', (tester) async {
      fakeExam.history.add(
        ExamHistorySummary(
          id: 'hist_1',
          date: DateTime(2026, 1, 1),
          unitId: 'b1-0',
          unitLabel: 'Travel',
          score: 80,
          questionCount: 10,
        ),
      );

      await tester.pumpWidget(wrapWithNavigation(const ExamHistoryPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Travel'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('ExamDetailPage delete removes exam from service', (tester) async {
      const examId = 'hist_delete';
      fakeExam.historyDetails[examId] = sampleExamHistoryDetail(id: examId);
      fakeExam.history.add(
        ExamHistorySummary(
          id: examId,
          date: DateTime(2026, 1, 1),
          unitId: 'b1-0',
          unitLabel: 'Travel',
          score: 80,
          questionCount: 1,
        ),
      );

      final nav = AppNavigationNotifier()..openExamDetail(examId);

      await tester.pumpWidget(
        wrapWithNavigation(ExamDetailPage(examId: examId), notifier: nav),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Exam Detail'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Delete exam?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeExam.historyDetails.containsKey(examId), isFalse);
      expect(fakeExam.history.any((item) => item.id == examId), isFalse);
      expect(nav.configuration.examDetailId, isNull);
    });
  });
}
