import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';

class UnitListPage extends StatelessWidget {
  const UnitListPage({super.key, required this.levelCode});

  final String levelCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Units • $levelCode')),
      body: Center(
        child: Text('UnitListPage stub for level $levelCode'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<AppNavigationNotifier>().openHomeRoute(
                HomeRoutePaths.termList,
                params: {'level': levelCode, 'unit': 'Unit 1'},
              );
        },
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
