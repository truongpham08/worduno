import 'package:flutter/foundation.dart';

import '../routes/route_paths.dart';

class AppNavigationNotifier extends ChangeNotifier {
  AppRoutePath _configuration = AppRoutePath.initial();

  AppRoutePath get configuration => _configuration;

  void selectTab(AppTab tab) {
    _configuration = _configuration.copyWith(
      tab: tab,
      clearExamDetail: true,
      clearCoachDetail: true,
    );
    notifyListeners();
  }

  void openHomeRoute(
    String path, {
    Map<String, String> params = const {},
  }) {
    _configuration = _configuration.copyWith(
      tab: AppTab.home,
      homeStack: [
        ..._configuration.homeStack,
        HomeStackEntry(path, params),
      ],
      clearExamDetail: true,
      clearCoachDetail: true,
    );
    notifyListeners();
  }

  bool popHomeRoute() {
    if (_configuration.homeStack.length <= 1) {
      return false;
    }

    final stack = List<HomeStackEntry>.from(_configuration.homeStack)
      ..removeLast();

    _configuration = _configuration.copyWith(homeStack: stack);
    notifyListeners();
    return true;
  }

  void openExamDetail(String examId) {
    _configuration = _configuration.copyWith(
      tab: AppTab.examHistory,
      examDetailId: examId,
      clearCoachDetail: true,
    );
    notifyListeners();
  }

  bool popExamDetail() {
    if (_configuration.examDetailId == null) {
      return false;
    }

    _configuration = _configuration.copyWith(clearExamDetail: true);
    notifyListeners();
    return true;
  }

  void openCoachDetail(String coachId) {
    _configuration = _configuration.copyWith(
      tab: AppTab.coachHistory,
      coachDetailId: coachId,
      clearExamDetail: true,
    );
    notifyListeners();
  }

  bool popCoachDetail() {
    if (_configuration.coachDetailId == null) {
      return false;
    }

    _configuration = _configuration.copyWith(clearCoachDetail: true);
    notifyListeners();
    return true;
  }
}
