import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:worduno/app/navigation/app_navigation_notifier.dart';

Widget wrapWithNavigation(
  Widget child, {
  AppNavigationNotifier? notifier,
}) {
  final nav = notifier ?? AppNavigationNotifier();
  return ChangeNotifierProvider<AppNavigationNotifier>.value(
    value: nav,
    child: MaterialApp(home: child),
  );
}
