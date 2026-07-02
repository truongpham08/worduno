import '../../../../core/database/app_database.dart';
import 'i_dashboard_local_data_source.dart';

class DashboardLocalDataSourceImpl implements IDashboardLocalDataSource {
  const DashboardLocalDataSourceImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<Map<String, Object?>>> getExamHistoryRows() async {
    final db = await _database.database;
    return db.rawQuery('''
      SELECT
        e.id,
        e.date,
        e.unit_id,
        e.score,
        COUNT(q.id) AS question_count
      FROM exam_history e
      LEFT JOIN question_history q ON q.exam_id = e.id
      GROUP BY e.id, e.date, e.unit_id, e.score
      ORDER BY e.date DESC
    ''');
  }

  @override
  Future<List<Map<String, Object?>>> getRecentCoachHistoryRows() async {
    final db = await _database.database;
    return db.query('coach_history', orderBy: 'date DESC', limit: 3);
  }
}
