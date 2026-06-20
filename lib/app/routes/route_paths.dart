enum AppTab {
  home,
  dashboard,
  examHistory,
  coachHistory,
}

class HomeRoutePaths {
  HomeRoutePaths._();

  static const levelList = '/';
  static const unitList = '/units';
  static const termList = '/terms';
  static const learn = '/learn';
  static const examConfig = '/exam/config';
  static const examSession = '/exam/session';
  static const examResult = '/exam/result';
  static const coachConfig = '/coach/config';
  static const coachSession = '/coach/session';
}

class HomeStackEntry {
  const HomeStackEntry(this.path, this.params);

  final String path;
  final Map<String, String> params;

  HomeStackEntry copyWith({
    String? path,
    Map<String, String>? params,
  }) {
    return HomeStackEntry(
      path ?? this.path,
      params ?? this.params,
    );
  }
}

class AppRoutePath {
  const AppRoutePath({
    required this.tab,
    required this.homeStack,
    this.examDetailId,
    this.coachDetailId,
  });

  factory AppRoutePath.initial() {
    return AppRoutePath(
      tab: AppTab.home,
      homeStack: [HomeStackEntry(HomeRoutePaths.levelList, const {})],
    );
  }

  final AppTab tab;
  final List<HomeStackEntry> homeStack;
  final String? examDetailId;
  final String? coachDetailId;

  AppRoutePath copyWith({
    AppTab? tab,
    List<HomeStackEntry>? homeStack,
    String? examDetailId,
    String? coachDetailId,
    bool clearExamDetail = false,
    bool clearCoachDetail = false,
  }) {
    return AppRoutePath(
      tab: tab ?? this.tab,
      homeStack: homeStack ?? this.homeStack,
      examDetailId:
          clearExamDetail ? null : examDetailId ?? this.examDetailId,
      coachDetailId:
          clearCoachDetail ? null : coachDetailId ?? this.coachDetailId,
    );
  }
}
