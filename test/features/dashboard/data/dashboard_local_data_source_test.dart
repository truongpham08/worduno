import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worduno/core/database/app_database.dart';
import 'package:worduno/features/dashboard/data/datasources/dashboard_local_data_source_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late String dbPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('worduno_dashboard_test');
    dbPath = p.join(tempDir.path, 'worduno_test.db');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'recent coach rows come from coach_feedback with dashboard aliases',
    () async {
      final appDatabase = AppDatabase(overridePath: dbPath);
      final db = await appDatabase.database;
      await db.insert('coach_feedback', {
        'id': 'feedback-1',
        'date': '2026-07-02T10:00:00.000',
        'unit_id': 'b1-0',
        'term_id': 'work out',
        'level_code': 'b1',
        'unit_name': 'Health',
        'definition': 'exercise',
        'user_sentence': 'I work out every morning.',
        'response_json':
            '{"grammar":"Good","vocabulary":"Good","naturalness":"Natural","suggestion":[]}',
      });

      final rows = await DashboardLocalDataSourceImpl(
        appDatabase,
      ).getRecentCoachHistoryRows();

      expect(rows, hasLength(1));
      expect(rows.single['id'], 'feedback-1');
      expect(rows.single['term_id'], 'work out');
      expect(rows.single['user_sentence'], 'I work out every morning.');
      expect(rows.single['response_json'], isNotEmpty);

      await appDatabase.close();
    },
  );
}
