import 'package:flutter/material.dart';

import '../../../../core/widgets/app_navigation_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: WordunoAppBar(title: 'Stats', showBack: false),
      body: Center(child: Text('DashboardPage stub')),
    );
  }
}
