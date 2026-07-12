import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worduno/core/database/app_database.dart';
import 'package:worduno/shared/vocabulary/data/datasources/i_vocabulary_remote_data_source.dart';
import 'package:worduno/shared/vocabulary/data/datasources/vocabulary_local_data_source_impl.dart';
import 'package:worduno/shared/vocabulary/data/dtos/level_dto.dart';
import 'package:worduno/shared/vocabulary/data/dtos/term_dto.dart';
import 'package:worduno/shared/vocabulary/data/dtos/unit_dto.dart';
import 'package:worduno/shared/vocabulary/data/repositories/vocabulary_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late String dbPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('worduno_vocab_test');
    dbPath = p.join(tempDir.path, 'worduno_vocab_test.db');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('vocabulary repository uses disk cache after first remote fetch', () async {
    final db = AppDatabase(overridePath: dbPath);
    final local = VocabularyLocalDataSourceImpl(db);
    final remote = _FakeRemoteDataSource();
    final repository = VocabularyRepositoryImpl(remote, local);

    final firstLevels = await repository.getLevels();
    expect(firstLevels.map((level) => level.code), ['b1', 'b2']);
    expect(remote.levelsCalls, 1);

    final firstUnits = await repository.getUnits('b1');
    expect(firstUnits.map((unit) => unit.name), ['Unit A']);
    expect(remote.unitsCalls, 1);

    final firstTerms = await repository.getTerms(
      levelCode: 'b1',
      unitName: 'Unit A',
    );
    expect(firstTerms.map((term) => term.text), ['add up']);
    expect(remote.termsCalls, 1);

    await db.close();

    final db2 = AppDatabase(overridePath: dbPath);
    final local2 = VocabularyLocalDataSourceImpl(db2);
    final remote2 = _FakeRemoteDataSource();
    final repository2 = VocabularyRepositoryImpl(remote2, local2);

    final cachedLevels = await repository2.getLevels();
    expect(cachedLevels.map((level) => level.code), ['b1', 'b2']);
    expect(remote2.levelsCalls, 0);

    final cachedUnits = await repository2.getUnits('b1');
    expect(cachedUnits.map((unit) => unit.name), ['Unit A']);
    expect(remote2.unitsCalls, 0);

    final cachedTerms = await repository2.getTerms(
      levelCode: 'b1',
      unitName: 'Unit A',
    );
    expect(cachedTerms.map((term) => term.text), ['add up']);
    expect(remote2.termsCalls, 0);

    await db2.close();
  });

  test('empty term list is cached and does not refetch remote', () async {
    final db = AppDatabase(overridePath: dbPath);
    final local = VocabularyLocalDataSourceImpl(db);
    final remote = _FakeRemoteDataSource(includeTerms: false);
    final repository = VocabularyRepositoryImpl(remote, local);

    await repository.getLevels();
    await repository.getUnits('b1');
    final firstTerms = await repository.getTerms(
      levelCode: 'b1',
      unitName: 'Unit A',
    );
    expect(firstTerms, isEmpty);
    expect(remote.termsCalls, 1);

    final secondTerms = await repository.getTerms(
      levelCode: 'b1',
      unitName: 'Unit A',
    );
    expect(secondTerms, isEmpty);
    expect(remote.termsCalls, 1);

    await db.close();
  });

  test('clearCache forces repository to fetch from remote again', () async {
    final db = AppDatabase(overridePath: dbPath);
    final local = VocabularyLocalDataSourceImpl(db);
    final remote = _FakeRemoteDataSource();
    final repository = VocabularyRepositoryImpl(remote, local);

    await repository.getLevels();
    expect(remote.levelsCalls, 1);

    await repository.clearCache();
    await repository.getLevels();
    expect(remote.levelsCalls, 2);

    await db.close();
  });
}

class _FakeRemoteDataSource implements IVocabularyRemoteDataSource {
  _FakeRemoteDataSource({this.includeTerms = true});

  final bool includeTerms;

  int levelsCalls = 0;
  int unitsCalls = 0;
  int termsCalls = 0;

  @override
  Future<List<LevelDto>> getLevels() async {
    levelsCalls++;
    return const [LevelDto(code: 'b1'), LevelDto(code: 'b2')];
  }

  @override
  Future<List<UnitDto>> getUnits(String levelCode) async {
    unitsCalls++;
    return [UnitDto(id: '$levelCode-0', name: 'Unit A')];
  }

  @override
  Future<List<TermDto>> getTerms({
    required String levelCode,
    required String unitName,
  }) async {
    termsCalls++;
    if (!includeTerms) {
      return const [];
    }
    return const [TermDto(id: 'add up', text: 'add up', definition: 'total')];
  }
}
