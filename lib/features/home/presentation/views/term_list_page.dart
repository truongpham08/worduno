import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';

class TermListPage extends StatelessWidget {
  const TermListPage({
    super.key,
    required this.levelCode,
    required this.unitName,
  });

  final String levelCode;
  final String unitName;

  @override
  Widget build(BuildContext context) {
    final navigation = context.read<AppNavigationNotifier>();

    return Scaffold(
      appBar: AppBar(title: Text('$unitName • Terms')),
      body: Center(
        child: Text('TermListPage stub for $levelCode / $unitName'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => navigation.openHomeRoute(
                    HomeRoutePaths.learn,
                    params: {
                      'level': levelCode,
                      'unit': unitName,
                    },
                  ),
                  child: const Text('Learn'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => navigation.openHomeRoute(
                    HomeRoutePaths.examConfig,
                    params: {
                      'level': levelCode,
                      'unit': unitName,
                    },
                  ),
                  child: const Text('Exam'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => navigation.openHomeRoute(
                    HomeRoutePaths.coachConfig,
                    params: {
                      'level': levelCode,
                      'unit': unitName,
                    },
                  ),
                  child: const Text('Coach'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
