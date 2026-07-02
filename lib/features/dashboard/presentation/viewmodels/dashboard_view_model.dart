import 'package:flutter/foundation.dart';
import '../../../../app/di/injection.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../application/services/i_dashboard_service.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({IDashboardService? dashboardService})
    : _dashboardService = dashboardService ?? getIt<IDashboardService>();

  final IDashboardService _dashboardService;

  bool isLoading = false;
  String? errorMessage;
  DashboardData? data;

  Future<void> loadDashboardData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      data = await _dashboardService.getDashboardData();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
