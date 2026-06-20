import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/user_word_state.dart';
import '../../domain/entities/word_status.dart';
import 'i_word_state_local_data_source.dart';

class WordStateLocalDataSourceImpl implements IWordStateLocalDataSource {
  WordStateLocalDataSourceImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<UserWordState>> getByUnit(String unitId) async {
    final db = await _database.database;
    final rows = await db.query(
      'user_word_states',
      where: 'unit_id = ?',
      whereArgs: [unitId],
    );

    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<UserWordState?> getByTerm({
    required String unitId,
    required String termId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'user_word_states',
      where: 'unit_id = ? AND term_id = ?',
      whereArgs: [unitId, termId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }
    return _mapRow(rows.first);
  }

  @override
  Future<void> upsert(UserWordState state) async {
    final db = await _database.database;
    await db.insert(
      'user_word_states',
      {
        'unit_id': state.unitId,
        'term_id': state.termId,
        'is_starred': state.isStarred ? 1 : 0,
        'status': state.status.storageValue,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  UserWordState _mapRow(Map<String, Object?> row) {
    return UserWordState(
      unitId: row['unit_id']! as String,
      termId: row['term_id']! as String,
      isStarred: (row['is_starred'] as int? ?? 0) == 1,
      status: WordStatus.fromStorage(row['status']! as String),
    );
  }
}
