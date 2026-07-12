import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/features/coach/data/repositories/coach_repository_impl.dart';
import 'package:worduno/features/coach/domain/entities/coach_entities.dart';
import 'package:worduno/features/coach/domain/entities/coach_star_filter.dart';
import 'package:worduno/features/dashboard/data/datasources/dashboard_local_data_source_impl.dart';
import 'package:worduno/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:worduno/features/home/presentation/viewmodels/term_list_view_model.dart';
import 'package:worduno/features/learning/data/repositories/learn_repository_impl.dart';
import 'package:worduno/features/learning/domain/entities/learn_session_data.dart';
import 'package:worduno/features/learning/presentation/viewmodels/learn_session_view_model.dart';
import 'package:worduno/shared/vocabulary/domain/entities/level.dart';
import 'package:worduno/shared/vocabulary/domain/entities/term.dart';
import 'package:worduno/shared/vocabulary/domain/entities/unit.dart';
import 'package:worduno/shared/word_state/application/services/word_state_service_impl.dart';
import 'package:worduno/shared/word_state/application/services/word_state_store.dart';
import 'package:worduno/shared/word_state/data/datasources/word_state_local_data_source_impl.dart';
import 'package:worduno/shared/word_state/data/repositories/word_state_repository_impl.dart';
import 'package:worduno/shared/word_state/domain/entities/word_status.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_database.dart';

void main() {
  initTestDatabase();

  late DirectoryHolder holder;

  setUp(() {
    holder = DirectoryHolder(createTempDbPath());
  });

  tearDown(() => holder.dispose());

  group('LearnRepositoryImpl', () {
    test('resolves unitId from unit name when not provided', () async {
      final vocab = FakeVocabularyService();
      final db = openTestDatabase(holder.dbPath);
      final store = wordStateStoreFor(db);
      final repo = LearnRepositoryImpl(vocab, store);

      final data = await repo.loadSessionData(
        levelCode: 'b1',
        unitName: 'Travel',
      );

      expect(data.unitId, 'b1-0');
      expect(data.terms, isNotEmpty);
      await db.close();
    });

    test('uses provided unitId directly', () async {
      final vocab = FakeVocabularyService();
      final db = openTestDatabase(holder.dbPath);
      final store = wordStateStoreFor(db);
      final repo = LearnRepositoryImpl(vocab, store);

      final data = await repo.loadSessionData(
        levelCode: 'b1',
        unitName: 'Travel',
        unitId: 'custom-id',
      );

      expect(data.unitId, 'custom-id');
      await db.close();
    });
  });

  group('LearnSessionViewModel', () {
    WordStateStore storeForTest() {
      return WordStateStore(
        WordStateRepositoryImpl(
          WordStateLocalDataSourceImpl(openTestDatabase(holder.dbPath)),
        ),
      );
    }

    test('markKnow advances session and persists status', () async {
      final learnService = FakeLearnService(
        LearnSessionData(
          unitId: 'b1-0',
          terms: sampleTerms(count: 2),
          states: const {},
        ),
      );
      final vm = LearnSessionViewModel(
        levelCode: 'b1',
        unitName: 'Travel',
        unitId: 'b1-0',
        learnService: learnService,
        wordStateStore: storeForTest(),
      );

      await vm.loadSession();
      expect(vm.currentTerm?.id, 'term0');

      await vm.markKnow();
      expect(learnService.statusUpdates.last.$2, WordStatus.know);
      expect(vm.currentTerm?.id, 'term1');
    });

    test('undo reverts session state', () async {
      final learnService = FakeLearnService(
        LearnSessionData(
          unitId: 'b1-0',
          terms: sampleTerms(count: 2),
          states: const {},
        ),
      );
      final vm = LearnSessionViewModel(
        levelCode: 'b1',
        unitName: 'Travel',
        unitId: 'b1-0',
        learnService: learnService,
        wordStateStore: storeForTest(),
      );

      await vm.loadSession();
      await vm.markKnow();
      await vm.undo();

      expect(vm.currentTerm?.id, 'term0');
      expect(vm.canUndo, isFalse);
    });

    test('loadSession sets error on failure', () async {
      final learnService = _ThrowingLearnService();
      final db = openTestDatabase(holder.dbPath);
      final vm = LearnSessionViewModel(
        levelCode: 'b1',
        unitName: 'Travel',
        learnService: learnService,
        wordStateStore: wordStateStoreFor(db),
      );

      await vm.loadSession();
      expect(vm.errorMessage, isNotNull);
      await db.close();
    });
  });

  group('TermListViewModel', () {
    test('knownCount reflects word states', () async {
      final vocab = FakeVocabularyService(
        termsByUnit: {
          'b1|Travel': sampleTerms(count: 3),
        },
      );
      final db = openTestDatabase(holder.dbPath);
      final store = wordStateStoreFor(db);
      await store.updateStatus(
        unitId: 'b1-0',
        termId: 'term0',
        status: WordStatus.know,
      );

      final vm = TermListViewModel(
        levelCode: 'b1',
        unitName: 'Travel',
        unitId: 'b1-0',
        vocabularyService: vocab,
        wordStateStore: store,
      );
      await vm.loadTerms();

      expect(vm.knownCount, 1);
      await db.close();
    });

    test('toggleStar updates store', () async {
      final vocab = FakeVocabularyService(
        termsByUnit: {
          'b1|Travel': [
            const Term(id: 't1', text: 'hello', definition: 'xin chao'),
          ],
        },
      );
      final db = openTestDatabase(holder.dbPath);
      final store = wordStateStoreFor(db);

      final vm = TermListViewModel(
        levelCode: 'b1',
        unitName: 'Travel',
        unitId: 'b1-0',
        vocabularyService: vocab,
        wordStateStore: store,
      );
      await vm.loadTerms();
      await vm.toggleStar('t1');

      expect(vm.getWordState('t1').isStarred, isTrue);
      await db.close();
    });

    test('loadTerms sets error on API failure', () async {
      final vocab = FakeVocabularyService(throwOnGetTerms: true);
      final db = openTestDatabase(holder.dbPath);
      final vm = TermListViewModel(
        levelCode: 'b1',
        unitName: 'Travel',
        vocabularyService: vocab,
        wordStateStore: wordStateStoreFor(db),
      );

      await vm.loadTerms();
      expect(vm.errorMessage, contains('Network error'));
      await db.close();
    });
  });

  group('CoachRepositoryImpl', () {
    test('buildSession respects word count', () async {
      final vocab = FakeVocabularyService(
        termsByUnit: {
          'b1|Travel': sampleTerms(count: 20),
        },
      );
      final db = openTestDatabase(holder.dbPath);
      final repo = CoachRepositoryImpl(
        vocab,
        wordStateStoreFor(db),
        StubCoachAiDataSource(),
        FakeCoachHistoryLocalDataSource(),
      );

      final session = await repo.buildSession(
        const CoachSessionConfig(
          levelCodes: ['b1'],
          unitKeys: [],
          starFilter: CoachStarFilter.all,
          wordCount: 5,
          fixedLevelCode: 'b1',
          fixedUnitName: 'Travel',
          fixedUnitId: 'b1-0',
        ),
      );

      expect(session.words.length, 5);
      await db.close();
    });

    test('buildSession throws when pool is empty', () async {
      final vocab = FakeVocabularyService(
        termsByUnit: {
          'b1|Travel': sampleTerms(count: 3),
        },
      );
      final db = openTestDatabase(holder.dbPath);
      final store = wordStateStoreFor(db);
      for (final term in sampleTerms(count: 3)) {
        await store.toggleStar(unitId: 'b1-0', termId: term.id);
      }

      final repo = CoachRepositoryImpl(
        vocab,
        store,
        StubCoachAiDataSource(),
        FakeCoachHistoryLocalDataSource(),
      );

      await expectLater(
        repo.buildSession(
          const CoachSessionConfig(
            levelCodes: ['b1'],
            unitKeys: [],
            starFilter: CoachStarFilter.notStarred,
            wordCount: 5,
            fixedLevelCode: 'b1',
            fixedUnitName: 'Travel',
            fixedUnitId: 'b1-0',
          ),
        ),
        throwsA(isA<StateError>()),
      );
      await db.close();
    });

    test('getExplanation caches AI response locally', () async {
      final vocab = FakeVocabularyService(
        termsByUnit: {
          'b1|Travel': [
            const Term(id: 't1', text: 'happy', definition: 'joy'),
          ],
        },
      );
      final db = openTestDatabase(holder.dbPath);
      final store = wordStateStoreFor(db);
      final repo = CoachRepositoryImpl(
        vocab,
        store,
        StubCoachAiDataSource(),
        FakeCoachHistoryLocalDataSource(),
      );

      const word = CoachWord(
        levelCode: 'b1',
        unitName: 'Travel',
        unitId: 'b1-0',
        term: Term(id: 't1', text: 'happy', definition: 'joy'),
      );

      final first = await repo.getExplanation(word);
      final cached = await repo.getCachedExplanation(
        unitId: 'b1-0',
        termId: 't1',
      );

      expect(first.usage, 'Common verb');
      expect(cached?.usage, 'Common verb');
      await db.close();
    });
  });

  group('DashboardRepositoryImpl', () {
    test('aggregates progress across levels and units', () async {
      final vocab = FakeVocabularyService(
        levels: const [
          Level(code: 'b1', totalTerms: 4, knownTerms: 0),
        ],
        unitsByLevel: const {
          'b1': [
            Unit(id: 'b1-0', name: 'Travel', totalTerms: 2, knownTerms: 0),
            Unit(id: 'b1-1', name: 'Food', totalTerms: 2, knownTerms: 0),
          ],
        },
        termsByUnit: {
          'b1|Travel': sampleTerms(count: 2, prefix: 'a'),
          'b1|Food': sampleTerms(count: 2, prefix: 'b'),
        },
      );
      final db = openTestDatabase(holder.dbPath);
      final wordStateService = WordStateServiceImpl(
        WordStateRepositoryImpl(WordStateLocalDataSourceImpl(db)),
      );
      await wordStateService.updateStatus(
        unitId: 'b1-0',
        termId: 'a0',
        status: WordStatus.learning,
      );
      await wordStateService.updateStatus(
        unitId: 'b1-1',
        termId: 'b0',
        status: WordStatus.know,
      );
      await wordStateService.updateStatus(
        unitId: 'b1-1',
        termId: 'b1',
        status: WordStatus.know,
      );

      final repo = DashboardRepositoryImpl(
        vocab,
        wordStateService,
        DashboardLocalDataSourceImpl(db),
      );

      final data = await repo.getDashboardData();

      expect(data.totalTerms, 4);
      expect(data.knownTerms, 2);
      expect(data.learningWordsCount, 1);
      expect(data.levelProgressList.single.levelName, 'Intermediate');
      expect(data.strongestUnits.single.unitName, 'Food');
      expect(data.weakestUnits.single.unitName, 'Travel');
      await db.close();
    });
  });
}

class DirectoryHolder {
  DirectoryHolder(({Directory tempDir, String dbPath}) record)
      : tempDir = record.tempDir,
        dbPath = record.dbPath;

  final Directory tempDir;
  final String dbPath;

  void dispose() => deleteTempDir(tempDir);
}

class _ThrowingLearnService extends FakeLearnService {
  _ThrowingLearnService()
      : super(
          const LearnSessionData(
            unitId: '',
            terms: [],
            states: {},
          ),
        );

  @override
  Future<LearnSessionData> loadSessionData({
    required String levelCode,
    required String unitName,
    String? unitId,
  }) async {
    throw Exception('Load failed');
  }
}
