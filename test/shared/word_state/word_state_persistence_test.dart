import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worduno/core/database/app_database.dart';
import 'package:worduno/shared/word_state/application/services/word_state_store.dart';
import 'package:worduno/shared/word_state/data/datasources/word_state_local_data_source_impl.dart';
import 'package:worduno/shared/word_state/data/repositories/word_state_repository_impl.dart';
import 'package:worduno/shared/word_state/domain/entities/word_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late String dbPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('worduno_test');
    dbPath = p.join(tempDir.path, 'worduno_test.db');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  WordStateRepositoryImpl repositoryFor(AppDatabase db) =>
      WordStateRepositoryImpl(WordStateLocalDataSourceImpl(db));

  test('word status survives reopening the database (real persistence)',
      () async {
    const unitId = 'b1-0';
    const termId = 'add up';

    final db1 = AppDatabase(overridePath: dbPath);
    final store = WordStateStore(repositoryFor(db1));

    await store.updateStatus(
      unitId: unitId,
      termId: termId,
      status: WordStatus.know,
    );

    expect(
      store.stateFor(unitId: unitId, termId: termId).status,
      WordStatus.know,
    );

    await db1.close();

    // Reopen with a brand-new connection: data must still be there.
    final db2 = AppDatabase(overridePath: dbPath);
    final repo2 = repositoryFor(db2);
    final persisted = await repo2.getByTerm(unitId: unitId, termId: termId);

    expect(persisted, isNotNull);
    expect(persisted!.status, WordStatus.know);
    expect(persisted.isStarred, isFalse);

    await db2.close();
  });

  test('star flag is persisted independently of status', () async {
    const unitId = 'b1-0';
    const termId = 'work out';

    final db1 = AppDatabase(overridePath: dbPath);
    final store = WordStateStore(repositoryFor(db1));

    await store.updateStatus(
      unitId: unitId,
      termId: termId,
      status: WordStatus.learning,
    );
    await store.toggleStar(unitId: unitId, termId: termId);

    await db1.close();

    final db2 = AppDatabase(overridePath: dbPath);
    final persisted =
        await repositoryFor(db2).getByTerm(unitId: unitId, termId: termId);

    expect(persisted, isNotNull);
    expect(persisted!.status, WordStatus.learning);
    expect(persisted.isStarred, isTrue);

    await db2.close();
  });

  test('store notifies listeners when a state changes', () async {
    final db = AppDatabase(overridePath: dbPath);
    final store = WordStateStore(repositoryFor(db));

    var notifications = 0;
    store.addListener(() => notifications++);

    await store.updateStatus(
      unitId: 'b1-0',
      termId: 't1',
      status: WordStatus.know,
    );

    expect(notifications, greaterThan(0));
    await db.close();
  });

  test('ensureLoaded reflects previously persisted state', () async {
    const unitId = 'b1-0';

    final db1 = AppDatabase(overridePath: dbPath);
    await repositoryFor(db1).updateStatus(
      unitId: unitId,
      termId: 'seed',
      status: WordStatus.know,
    );
    await db1.close();

    final db2 = AppDatabase(overridePath: dbPath);
    final store = WordStateStore(repositoryFor(db2));
    await store.ensureLoaded(unitId);

    expect(store.knownCount(unitId), 1);
    expect(store.stateFor(unitId: unitId, termId: 'seed').status,
        WordStatus.know);

    await db2.close();
  });
}
