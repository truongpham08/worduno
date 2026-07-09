import 'package:flutter_test/flutter_test.dart';
import 'package:worduno/app/navigation/app_navigation_notifier.dart';
import 'package:worduno/app/routes/route_paths.dart';

void main() {
  group('AppNavigationNotifier', () {
    late AppNavigationNotifier notifier;

    setUp(() {
      notifier = AppNavigationNotifier();
    });

    test('starts on home tab at level list', () {
      expect(notifier.configuration.tab, AppTab.home);
      expect(notifier.configuration.homeStack.last.path, HomeRoutePaths.levelList);
    });

    test('selectTab switches bottom navigation', () {
      notifier.selectTab(AppTab.dashboard);
      expect(notifier.configuration.tab, AppTab.dashboard);
    });

    test('openHomeRoute pushes onto home stack', () {
      notifier.openHomeRoute(
        HomeRoutePaths.unitList,
        params: {'level': 'b1'},
      );
      expect(notifier.configuration.homeStack.length, 2);
      expect(notifier.configuration.homeStack.last.path, HomeRoutePaths.unitList);
    });

    test('popHomeRoute removes last entry', () {
      notifier.openHomeRoute(HomeRoutePaths.unitList, params: {'level': 'b1'});
      expect(notifier.popHomeRoute(), isTrue);
      expect(notifier.configuration.homeStack.length, 1);
    });

    test('popHomeRoute returns false at root', () {
      expect(notifier.popHomeRoute(), isFalse);
    });

    test('openExamDetail switches to exam history tab', () {
      notifier.openExamDetail('exam_1');
      expect(notifier.configuration.tab, AppTab.examHistory);
      expect(notifier.configuration.examDetailId, 'exam_1');
    });

    test('popExamDetail clears detail id', () {
      notifier.openExamDetail('exam_1');
      expect(notifier.popExamDetail(), isTrue);
      expect(notifier.configuration.examDetailId, isNull);
    });

    test('resetHomeToRoot clears nested stack', () {
      notifier.openHomeRoute(HomeRoutePaths.unitList, params: {'level': 'b1'});
      notifier.openHomeRoute(HomeRoutePaths.termList, params: {'level': 'b1'});
      notifier.resetHomeToRoot();
      expect(notifier.configuration.homeStack.length, 1);
    });
  });
}
