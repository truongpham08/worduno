import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../dtos/level_dto.dart';
import '../dtos/term_dto.dart';
import '../dtos/unit_dto.dart';
import 'i_vocabulary_local_data_source.dart';

class VocabularyLocalDataSourceImpl implements IVocabularyLocalDataSource {
  VocabularyLocalDataSourceImpl(this._database);

  final AppDatabase _database;

  @override
  Future<bool> hasLevels() async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT 1 FROM vocabulary_levels LIMIT 1',
    );
    return result.isNotEmpty;
  }

  @override
  Future<List<LevelDto>> getLevels() async {
    final db = await _database.database;
    final rows = await db.query(
      'vocabulary_levels',
      orderBy: 'sort_order ASC',
    );

    return rows
        .map(
          (row) => LevelDto(code: row['code']! as String),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveLevels(List<LevelDto> levels) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('vocabulary_levels');
      for (var index = 0; index < levels.length; index++) {
        await txn.insert('vocabulary_levels', {
          'code': levels[index].code,
          'sort_order': index,
        });
      }
    });
  }

  @override
  Future<bool> hasUnits(String levelCode) async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT 1 FROM vocabulary_units WHERE level_code = ? LIMIT 1',
      [levelCode],
    );
    return result.isNotEmpty;
  }

  @override
  Future<List<UnitDto>> getUnits(String levelCode) async {
    final db = await _database.database;
    final rows = await db.query(
      'vocabulary_units',
      where: 'level_code = ?',
      whereArgs: [levelCode],
      orderBy: 'sort_order ASC',
    );

    return rows
        .map(
          (row) => UnitDto(
            id: row['id']! as String,
            name: row['name']! as String,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveUnits(String levelCode, List<UnitDto> units) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        'vocabulary_units',
        where: 'level_code = ?',
        whereArgs: [levelCode],
      );
      for (var index = 0; index < units.length; index++) {
        await txn.insert('vocabulary_units', {
          'id': units[index].id,
          'level_code': levelCode,
          'name': units[index].name,
          'sort_order': index,
        });
      }
    });
  }

  @override
  Future<bool> hasTerms({
    required String levelCode,
    required String unitName,
  }) async {
    final db = await _database.database;
    final result = await db.rawQuery(
      '''
      SELECT 1
      FROM vocabulary_cached_units
      WHERE level_code = ? AND unit_name = ?
      LIMIT 1
      ''',
      [levelCode, unitName],
    );
    return result.isNotEmpty;
  }

  @override
  Future<List<TermDto>> getTerms({
    required String levelCode,
    required String unitName,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'vocabulary_terms',
      where: 'level_code = ? AND unit_name = ?',
      whereArgs: [levelCode, unitName],
      orderBy: 'sort_order ASC',
    );

    return rows
        .map(
          (row) => TermDto(
            id: row['id']! as String,
            text: row['text']! as String,
            definition: row['definition']! as String,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveTerms({
    required String levelCode,
    required String unitName,
    required String unitId,
    required List<TermDto> terms,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        'vocabulary_terms',
        where: 'level_code = ? AND unit_name = ?',
        whereArgs: [levelCode, unitName],
      );
      for (var index = 0; index < terms.length; index++) {
        final term = terms[index];
        await txn.insert(
          'vocabulary_terms',
          {
            'id': term.id,
            'level_code': levelCode,
            'unit_name': unitName,
            'unit_id': unitId,
            'text': term.text,
            'definition': term.definition,
            'sort_order': index,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.insert(
        'vocabulary_cached_units',
        {
          'level_code': levelCode,
          'unit_name': unitName,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> clearAll() async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('vocabulary_terms');
      await txn.delete('vocabulary_cached_units');
      await txn.delete('vocabulary_units');
      await txn.delete('vocabulary_levels');
    });
  }
}
