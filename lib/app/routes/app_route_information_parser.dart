import 'package:flutter/material.dart';

import 'route_paths.dart';

class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final location = routeInformation.uri.path;

    switch (location) {
      case '/dashboard':
        return AppRoutePath.initial().copyWith(tab: AppTab.dashboard);
      case '/exam-history':
        return AppRoutePath.initial().copyWith(tab: AppTab.examHistory);
      case '/coach-history':
        return AppRoutePath.initial().copyWith(tab: AppTab.coachHistory);
      default:
        return AppRoutePath.initial();
    }
  }

  @override
  RouteInformation restoreRouteInformation(AppRoutePath configuration) {
    final location = switch (configuration.tab) {
      AppTab.home => '/',
      AppTab.dashboard => '/dashboard',
      AppTab.examHistory => '/exam-history',
      AppTab.coachHistory => '/coach-history',
    };

    return RouteInformation(uri: Uri.parse(location));
  }
}
