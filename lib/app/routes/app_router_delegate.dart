import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/coach/presentation/views/coach_pages.dart';
import '../../features/dashboard/presentation/views/dashboard_page.dart';
import '../../features/exam/presentation/views/exam_pages.dart';
import '../../features/home/presentation/viewmodels/level_list_view_model.dart';
import '../../features/home/presentation/views/level_list_page.dart';
import '../../features/home/presentation/views/term_list_page.dart';
import '../../features/home/presentation/views/unit_list_page.dart';
import '../../features/learning/presentation/views/learn_session_page.dart';
import '../navigation/app_navigation_notifier.dart';
import '../shell/app_shell.dart';
import 'route_paths.dart';

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier {
  AppRouterDelegate({required AppNavigationNotifier navigationNotifier})
      : _navigationNotifier = navigationNotifier {
    _navigationNotifier.addListener(notifyListeners);
  }

  final AppNavigationNotifier _navigationNotifier;

  @override
  void dispose() {
    _navigationNotifier.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  AppRoutePath get currentConfiguration => _navigationNotifier.configuration;

  @override
  Widget build(BuildContext context) {
    final configuration = _navigationNotifier.configuration;

    return Navigator(
      pages: [
        MaterialPage<void>(
          key: const ValueKey('app-shell'),
          child: AppShell(
            currentTab: configuration.tab,
            onTabSelected: _navigationNotifier.selectTab,
            body: _buildTabNavigator(configuration),
          ),
        ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        return switch (_navigationNotifier.configuration.tab) {
          AppTab.home => _navigationNotifier.popHomeRoute(),
          AppTab.examHistory => _navigationNotifier.popExamDetail(),
          AppTab.coachHistory => _navigationNotifier.popCoachRoute(),
          AppTab.dashboard => false,
        };
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    _navigationNotifier.selectTab(configuration.tab);
  }

  @override
  Future<bool> popRoute() async {
    return switch (_navigationNotifier.configuration.tab) {
      AppTab.home => _navigationNotifier.popHomeRoute(),
      AppTab.examHistory => _navigationNotifier.popExamDetail(),
      AppTab.coachHistory => _navigationNotifier.popCoachRoute(),
      AppTab.dashboard => false,
    };
  }

  Widget _buildTabNavigator(AppRoutePath configuration) {
    return switch (configuration.tab) {
      AppTab.home => _buildHomeNavigator(configuration.homeStack),
      AppTab.dashboard => const DashboardPage(),
      AppTab.examHistory => _buildExamHistoryNavigator(configuration),
      AppTab.coachHistory => _buildCoachHistoryNavigator(configuration),
    };
  }

  Widget _buildHomeNavigator(List<HomeStackEntry> stack) {
    return Navigator(
      pages: [
        for (final entry in stack) _buildHomePage(entry),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        return _navigationNotifier.popHomeRoute();
      },
    );
  }

  Page<void> _buildHomePage(HomeStackEntry entry) {
    final child = switch (entry.path) {
      HomeRoutePaths.levelList => ChangeNotifierProvider(
          create: (_) => LevelListViewModel(),
          child: const LevelListPage(),
        ),
      HomeRoutePaths.unitList => UnitListPage(
          levelCode: entry.params['level'] ?? '',
        ),
      HomeRoutePaths.termList => TermListPage(
          levelCode: entry.params['level'] ?? '',
          unitName: entry.params['unit'] ?? '',
          unitId: entry.params['unitId'],
        ),
      HomeRoutePaths.learn => LearnSessionPage(
          levelCode: entry.params['level'] ?? '',
          unitName: entry.params['unit'] ?? '',
          unitId: entry.params['unitId'],
          initialTermId: entry.params['termId'],
        ),
      HomeRoutePaths.examConfig => ExamConfigPage(
          levelCode: entry.params['level'],
          unitName: entry.params['unit'],
        ),
      HomeRoutePaths.examSession => const ExamSessionPage(),
      HomeRoutePaths.examResult => const ExamResultPage(),
      HomeRoutePaths.coachConfig => CoachConfigPage(
          levelCode: entry.params['level'],
          unitName: entry.params['unit'],
        ),
      HomeRoutePaths.coachSession => const CoachSessionPage(),
      _ => const Scaffold(
          body: Center(child: Text('Unknown home route')),
        ),
    };

    return MaterialPage<void>(
      key: ValueKey('${entry.path}:${entry.params}'),
      child: child,
    );
  }

  Widget _buildExamHistoryNavigator(AppRoutePath configuration) {
    return Navigator(
      pages: [
        const MaterialPage<void>(
          key: ValueKey('exam-history-list'),
          child: ExamHistoryPage(),
        ),
        if (configuration.examDetailId != null)
          MaterialPage<void>(
            key: ValueKey('exam-detail-${configuration.examDetailId}'),
            child: ExamDetailPage(examId: configuration.examDetailId!),
          ),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        return _navigationNotifier.popExamDetail();
      },
    );
  }

  Widget _buildCoachHistoryNavigator(AppRoutePath configuration) {
    return Navigator(
      pages: [
        for (final entry in configuration.coachStack)
          _buildCoachHistoryPage(entry),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        return _navigationNotifier.popCoachRoute();
      },
    );
  }

  Page<void> _buildCoachHistoryPage(CoachStackEntry entry) {
    final child = switch (entry.path) {
      CoachRoutePaths.list => const CoachHistoryPage(),
      CoachRoutePaths.word => CoachWordHistoryPage(
          unitId: entry.params['unitId'] ?? '',
          termId: entry.params['termId'] ?? '',
        ),
      CoachRoutePaths.feedback => CoachFeedbackDetailPage(
          feedbackId: entry.params['feedbackId'] ?? '',
        ),
      _ => const Scaffold(
          body: Center(child: Text('Unknown coach route')),
        ),
    };

    return MaterialPage<void>(
      key: ValueKey('${entry.path}:${entry.params}'),
      child: child,
    );
  }
}
