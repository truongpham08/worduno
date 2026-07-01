import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  /// [overridePath] lets tests point the database at a temporary file so
  /// persistence can be verified across separate connections.
  AppDatabase({String? overridePath}) : _overridePath = overridePath;

  final String? _overridePath;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    _database = await _open();
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Database> _open() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final path = _overridePath ?? join(await getDatabasesPath(), 'worduno.db');

    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createV5Schema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE user_word_states ADD COLUMN explanation TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS coach_history');
          await db.execute('DROP TABLE IF EXISTS coach_feedback');
          await db.execute('DROP TABLE IF EXISTS coach_session_words');
          await db.execute('DROP TABLE IF EXISTS coach_sessions');
          await db.execute(_coachFeedbackTableSql);
        }
        if (oldVersion < 5) {
          await _addColumnIfMissing(
            db,
            table: 'question_history',
            column: 'is_correct',
            definition: 'INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  static const _coachFeedbackTableSql = '''
    CREATE TABLE coach_feedback (
      id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      unit_id TEXT NOT NULL,
      term_id TEXT NOT NULL,
      level_code TEXT NOT NULL,
      unit_name TEXT NOT NULL,
      definition TEXT NOT NULL,
      user_sentence TEXT NOT NULL,
      response_json TEXT NOT NULL,
      FOREIGN KEY (unit_id, term_id) REFERENCES user_word_states (unit_id, term_id)
    )
  ''';

  Future<void> _createV5Schema(Database db) async {
    await db.execute('''
      CREATE TABLE user_word_states (
        unit_id TEXT NOT NULL,
        term_id TEXT NOT NULL,
        is_starred INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'new',
        explanation TEXT,
        PRIMARY KEY (unit_id, term_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE exam_history (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        unit_id TEXT NOT NULL,
        score REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE question_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id TEXT NOT NULL,
        type TEXT NOT NULL,
        question TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (exam_id) REFERENCES exam_history (id)
      )
    ''');

    await db.execute(_coachFeedbackTableSql);
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}
