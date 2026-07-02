import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/app/app.dart';
import 'package:worduno/app/di/injection.dart';
import 'package:worduno/features/dashboard/application/models/dashboard_data.dart';
import 'package:worduno/features/dashboard/application/services/i_dashboard_service.dart';
import 'package:worduno/shared/vocabulary/application/services/i_vocabulary_service.dart';
import 'package:worduno/shared/vocabulary/domain/entities/level.dart';
import 'package:worduno/shared/vocabulary/domain/entities/term.dart';
import 'package:worduno/shared/vocabulary/domain/entities/unit.dart';

void main() {
  setUpAll(() async {
    await setupDependencies();
    await getIt.unregister<IVocabularyService>();
    await getIt.unregister<IDashboardService>();
    getIt.registerLazySingleton<IVocabularyService>(_FakeVocabularyService.new);
    getIt.registerLazySingleton<IDashboardService>(_FakeDashboardService.new);
  });

  testWidgets('app launches with bottom navigation', (tester) async {
    await tester.pumpWidget(const WordunoApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Your Levels'), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs', (tester) async {
    await tester.pumpWidget(const WordunoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('OVERALL PROGRESS'), findsOneWidget);
  });
}

class _FakeVocabularyService implements IVocabularyService {
  @override
  Future<List<Level>> getLevels() async => const [
    Level(code: 'b1', totalTerms: 2, knownTerms: 1),
  ];

  @override
  Future<List<Unit>> getUnits(String levelCode) async => const [
    Unit(id: 'b1-0', name: 'Travel', totalTerms: 2, knownTerms: 1),
  ];

  @override
  Future<List<Term>> getTerms({
    required String levelCode,
    required String unitName,
  }) async => const [
    Term(id: 'hello', text: 'hello', definition: 'xin chao'),
    Term(id: 'world', text: 'world', definition: 'the gioi'),
  ];
}

class _FakeDashboardService implements IDashboardService {
  @override
  Future<DashboardData> getDashboardData() async {
    return const DashboardData(
      overallProgress: 0.5,
      totalTerms: 2,
      knownTerms: 1,
      learnedWordsCount: 1,
      learningWordsCount: 1,
      starredWordsCount: 0,
      levelProgressList: [
        LevelProgressData(
          levelCode: 'b1',
          levelName: 'Intermediate',
          progress: 0.5,
          knownTerms: 1,
          totalTerms: 2,
        ),
      ],
      examCount: 0,
      averageExamScore: 0,
      strongestUnits: [
        UnitProgressData(unitId: 'b1-0', unitName: 'Travel', progress: 0.5),
      ],
      weakestUnits: [
        UnitProgressData(unitId: 'b1-0', unitName: 'Travel', progress: 0.5),
      ],
      recentExams: [],
      recentCoachFeedback: [],
    );
  }
}
