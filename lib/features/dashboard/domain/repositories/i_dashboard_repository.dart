import '../entities/dashboard_data.dart';

abstract class IDashboardRepository {
  Future<DashboardData> getDashboardData();
}
