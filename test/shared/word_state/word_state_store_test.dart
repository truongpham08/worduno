import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

  group('WordStateStore', () {
    test('returns default state for unknown term', () {
      final db = openTestDatabase(holder.dbPath);
      final store = wordStateStoreFor(db);

      final state = store.stateFor(unitId: 'b1-0', termId: 'unknown');
      expect(state.status, WordStatus.newWord);
      expect(state.isStarred, isFalse);
    });

    test('rolls back optimistic update when persist fails', () async {
      final db = openTestDatabase(holder.dbPath);
      final baseRepo = WordStateRepositoryImpl(
        WordStateLocalDataSourceImpl(db),
      );
      final failingRepo = FailingWordStateRepository(baseRepo)
        ..failNextUpdate = true;
      final store = WordStateStore(failingRepo);

      await expectLater(
        store.updateStatus(
          unitId: 'b1-0',
          termId: 't1',
          status: WordStatus.know,
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        store.stateFor(unitId: 'b1-0', termId: 't1').status,
        WordStatus.newWord,
      );
      await db.close();
    });

    test('saveExplanation persists and reloads from cache', () async {
      final db = openTestDatabase(holder.dbPath);
      final store = wordStateStoreFor(db);

      await store.saveExplanation(
        unitId: 'b1-0',
        termId: 't1',
        explanationJson: '{"usage":"test"}',
      );

      expect(
        store.stateFor(unitId: 'b1-0', termId: 't1').explanation,
        '{"usage":"test"}',
      );
      await db.close();
    });

    test('ensurePersisted creates row for coach feedback FK', () async {
      final db = openTestDatabase(holder.dbPath);
      final store = wordStateStoreFor(db);

      await store.ensurePersisted(unitId: 'b1-0', termId: 'coach-word');
      final repo = WordStateRepositoryImpl(WordStateLocalDataSourceImpl(db));
      final persisted = await repo.getByTerm(
        unitId: 'b1-0',
        termId: 'coach-word',
      );

      expect(persisted, isNotNull);
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
