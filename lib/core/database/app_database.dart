import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'worduno.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_word_states (
            unit_id TEXT NOT NULL,
            term_id TEXT NOT NULL,
            is_starred INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'new',
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
            FOREIGN KEY (exam_id) REFERENCES exam_history (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE coach_history (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            word TEXT NOT NULL,
            user_sentence TEXT NOT NULL,
            grammar_feedback TEXT NOT NULL,
            vocabulary_feedback TEXT NOT NULL,
            naturalness_feedback TEXT NOT NULL,
            suggestion_feedback TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
