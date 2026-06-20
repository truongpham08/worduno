import 'package:flutter/material.dart';

import '../routes/route_paths.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.body,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;
  final Widget body;

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: 'Exam History',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_outlined),
      activeIcon: Icon(Icons.chat),
      label: 'Coach History',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentTab.index,
        onTap: (index) => onTabSelected(AppTab.values[index]),
        items: _items,
      ),
    );
  }
}
