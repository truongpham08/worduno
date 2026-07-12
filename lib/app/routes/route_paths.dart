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

class CoachRoutePaths {
  CoachRoutePaths._();

  static const list = '/';
  static const word = '/word';
  static const feedback = '/feedback';
  static const config = '/config';
  static const session = '/session';
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

class CoachStackEntry {
  const CoachStackEntry(this.path, this.params);

  final String path;
  final Map<String, String> params;
}

class AppRoutePath {
  const AppRoutePath({
    required this.tab,
    required this.homeStack,
    required this.coachStack,
    this.examDetailId,
  });

  factory AppRoutePath.initial() {
    return AppRoutePath(
      tab: AppTab.home,
      homeStack: [HomeStackEntry(HomeRoutePaths.levelList, const {})],
      coachStack: [CoachStackEntry(CoachRoutePaths.list, const {})],
    );
  }

  final AppTab tab;
  final List<HomeStackEntry> homeStack;
  final List<CoachStackEntry> coachStack;
  final String? examDetailId;

  AppRoutePath copyWith({
    AppTab? tab,
    List<HomeStackEntry>? homeStack,
    List<CoachStackEntry>? coachStack,
    String? examDetailId,
    bool clearExamDetail = false,
    bool clearCoachStack = false,
  }) {
    return AppRoutePath(
      tab: tab ?? this.tab,
      homeStack: homeStack ?? this.homeStack,
      coachStack: clearCoachStack
          ? [CoachStackEntry(CoachRoutePaths.list, const {})]
          : coachStack ?? this.coachStack,
      examDetailId:
          clearExamDetail ? null : examDetailId ?? this.examDetailId,
    );
  }
}
