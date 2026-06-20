import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../viewmodels/level_list_view_model.dart';

class LevelListPage extends StatefulWidget {
  const LevelListPage({super.key});

  @override
  State<LevelListPage> createState() => _LevelListPageState();
}

class _LevelListPageState extends State<LevelListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LevelListViewModel>().loadLevels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LevelListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<AppNavigationNotifier>().openHomeRoute(
                HomeRoutePaths.examConfig,
              );
        },
        label: const Text('Create Exam'),
        icon: const Icon(Icons.quiz_outlined),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, LevelListViewModel viewModel) {
    if (viewModel.isLoading) {
      return const AppLoading(message: 'Loading levels...');
    }

    if (viewModel.errorMessage != null) {
      return AppErrorView(
        message: viewModel.errorMessage!,
        onRetry: viewModel.loadLevels,
      );
    }

    if (viewModel.levels.isEmpty) {
      return const Center(child: Text('No levels available yet.'));
    }

    return ListView.separated(
      itemCount: viewModel.levels.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final level = viewModel.levels[index];
        return ListTile(
          title: Text(level.code),
          subtitle: Text(
            '${level.knownTerms}/${level.totalTerms} known • '
            '${(level.progress * 100).toStringAsFixed(0)}%',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.read<AppNavigationNotifier>().openHomeRoute(
                  HomeRoutePaths.unitList,
                  params: {'level': level.code},
                );
          },
        );
      },
    );
  }
}
