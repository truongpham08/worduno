import 'package:flutter/foundation.dart';

import '../routes/route_paths.dart';

class AppNavigationNotifier extends ChangeNotifier {
  AppRoutePath _configuration = AppRoutePath.initial();

  AppRoutePath get configuration => _configuration;

  void selectTab(AppTab tab) {
    _configuration = _configuration.copyWith(
      tab: tab,
      clearExamDetail: true,
      clearCoachStack: tab != AppTab.coachHistory,
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
      clearCoachStack: true,
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
      clearCoachStack: true,
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

  void _openCoachRoute(String path, Map<String, String> params) {
    _configuration = _configuration.copyWith(
      tab: AppTab.coachHistory,
      coachStack: [
        ..._configuration.coachStack,
        CoachStackEntry(path, params),
      ],
      clearExamDetail: true,
    );
    notifyListeners();
  }

  void openCoachTermDetail({
    required String unitId,
    required String termId,
  }) {
    _openCoachRoute(CoachRoutePaths.word, {
      'unitId': unitId,
      'termId': termId,
    });
  }

  void openCoachFeedbackDetail(String feedbackId) {
    _openCoachRoute(CoachRoutePaths.feedback, {'feedbackId': feedbackId});
  }

  void resetHomeToRoot() {
    _configuration = _configuration.copyWith(
      tab: AppTab.home,
      homeStack: [HomeStackEntry(HomeRoutePaths.levelList, const {})],
      clearExamDetail: true,
      clearCoachStack: true,
    );
    notifyListeners();
  }

  bool popCoachRoute() {
    if (_configuration.coachStack.length <= 1) {
      return false;
    }

    final stack = List<CoachStackEntry>.from(_configuration.coachStack)
      ..removeLast();

    _configuration = _configuration.copyWith(coachStack: stack);
    notifyListeners();
    return true;
  }

  void startCoachFromHistory() {
    _configuration = _configuration.copyWith(
      tab: AppTab.coachHistory,
      coachStack: const [
        CoachStackEntry(CoachRoutePaths.list, {}),
        CoachStackEntry(CoachRoutePaths.config, {}),
      ],
      clearExamDetail: true,
    );
    notifyListeners();
  }

  void openCoachSession() {
    if (_configuration.tab == AppTab.coachHistory) {
      _openCoachRoute(CoachRoutePaths.session, const {});
      return;
    }
    openHomeRoute(HomeRoutePaths.coachSession);
  }

  void completeCoachSessionAndOpenHistory() {
    _configuration = _configuration.copyWith(
      tab: AppTab.coachHistory,
      homeStack: const [HomeStackEntry(HomeRoutePaths.levelList, {})],
      coachStack: const [CoachStackEntry(CoachRoutePaths.list, {})],
      clearExamDetail: true,
    );
    notifyListeners();
  }
}
