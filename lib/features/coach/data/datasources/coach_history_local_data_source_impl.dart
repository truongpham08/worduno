import '../../../../core/database/app_database.dart';
import '../../domain/entities/coach_entities.dart';
import 'i_coach_history_local_data_source.dart';

class CoachHistoryLocalDataSourceImpl implements ICoachHistoryLocalDataSource {
  CoachHistoryLocalDataSourceImpl(this._database);

  final AppDatabase _database;

  @override
  Future<void> insertFeedback(CoachFeedbackEntry entry) async {
    final db = await _database.database;
    await db.insert('coach_feedback', {
      'id': entry.id,
      'date': entry.date.toIso8601String(),
      'unit_id': entry.unitId,
      'term_id': entry.termId,
      'level_code': entry.levelCode,
      'unit_name': entry.unitName,
      'definition': entry.definition,
      'user_sentence': entry.userSentence,
      'response_json': entry.responseJson,
    });
  }

  @override
  Future<List<CoachHistoryTerm>> getCoachedTerms() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT
        unit_id,
        term_id,
        level_code,
        unit_name,
        definition,
        MAX(date) AS last_coached_at,
        COUNT(*) AS feedback_count
      FROM coach_feedback
      GROUP BY unit_id, term_id, level_code, unit_name, definition
      ORDER BY last_coached_at DESC
    ''');

    return rows.map(_mapCoachedTermRow).toList(growable: false);
  }

  @override
  Future<CoachHistoryTerm?> getCoachedTerm({
    required String unitId,
    required String termId,
  }) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        unit_id,
        term_id,
        level_code,
        unit_name,
        definition,
        MAX(date) AS last_coached_at,
        COUNT(*) AS feedback_count
      FROM coach_feedback
      WHERE unit_id = ? AND term_id = ?
      GROUP BY unit_id, term_id, level_code, unit_name, definition
      ''',
      [unitId, termId],
    );
    if (rows.isEmpty) return null;
    return _mapCoachedTermRow(rows.first);
  }

  @override
  Future<List<CoachFeedbackEntry>> getFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'coach_feedback',
      where: 'unit_id = ? AND term_id = ?',
      whereArgs: [unitId, termId],
      orderBy: 'date DESC',
    );
    return rows.map(_mapFeedbackRow).toList(growable: false);
  }

  @override
  Future<CoachFeedbackEntry?> getFeedbackById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'coach_feedback',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _mapFeedbackRow(rows.first);
  }

  @override
  Future<void> deleteFeedback(String feedbackId) async {
    final db = await _database.database;
    await db.delete(
      'coach_feedback',
      where: 'id = ?',
      whereArgs: [feedbackId],
    );
  }

  @override
  Future<void> deleteAllFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) async {
    final db = await _database.database;
    await db.delete(
      'coach_feedback',
      where: 'unit_id = ? AND term_id = ?',
      whereArgs: [unitId, termId],
    );
  }

  CoachHistoryTerm _mapCoachedTermRow(Map<String, Object?> row) {
    return CoachHistoryTerm(
      unitId: row['unit_id']! as String,
      termId: row['term_id']! as String,
      levelCode: row['level_code']! as String,
      unitName: row['unit_name']! as String,
      definition: row['definition']! as String,
      lastCoachedAt: DateTime.parse(row['last_coached_at']! as String),
      feedbackCount: row['feedback_count']! as int,
    );
  }

  CoachFeedbackEntry _mapFeedbackRow(Map<String, Object?> row) {
    return CoachFeedbackEntry(
      id: row['id']! as String,
      date: DateTime.parse(row['date']! as String),
      unitId: row['unit_id']! as String,
      termId: row['term_id']! as String,
      levelCode: row['level_code']! as String,
      unitName: row['unit_name']! as String,
      definition: row['definition']! as String,
      userSentence: row['user_sentence']! as String,
      responseJson: row['response_json']! as String,
    );
  }
}
