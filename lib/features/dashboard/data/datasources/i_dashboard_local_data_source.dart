abstract class IDashboardLocalDataSource {
  Future<List<Map<String, Object?>>> getExamHistoryRows();

  Future<List<Map<String, Object?>>> getRecentCoachHistoryRows();
}
