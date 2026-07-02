import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_navigation_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: WordunoAppBar(title: 'Stats', showBack: false),
      body: Center(child: Text('DashboardPage stub')),
    );
  }
}
