import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/i_dashboard_repository.dart';
import 'i_dashboard_service.dart';

class DashboardServiceImpl implements IDashboardService {
  const DashboardServiceImpl(this._dashboardRepository);

  final IDashboardRepository _dashboardRepository;

  @override
  Future<DashboardData> getDashboardData() =>
      _dashboardRepository.getDashboardData();
}
