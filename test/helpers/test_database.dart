import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worduno/core/database/app_database.dart';
import 'package:worduno/shared/word_state/application/services/word_state_store.dart';
import 'package:worduno/shared/word_state/data/datasources/word_state_local_data_source_impl.dart';
import 'package:worduno/shared/word_state/data/repositories/word_state_repository_impl.dart';

/// Initializes sqflite FFI for desktop test runs.
void initTestDatabase() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Creates a temp directory and database path for an isolated test run.
({Directory tempDir, String dbPath}) createTempDbPath() {
  final tempDir = Directory.systemTemp.createTempSync('worduno_test');
  final dbPath = p.join(tempDir.path, 'worduno_test.db');
  return (tempDir: tempDir, dbPath: dbPath);
}

AppDatabase openTestDatabase(String dbPath) => AppDatabase(overridePath: dbPath);

WordStateStore wordStateStoreFor(AppDatabase db) {
  final repo = WordStateRepositoryImpl(WordStateLocalDataSourceImpl(db));
  return WordStateStore(repo);
}

void deleteTempDir(Directory tempDir) {
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }
}
