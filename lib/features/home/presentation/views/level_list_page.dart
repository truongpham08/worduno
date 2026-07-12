import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../../../shared/vocabulary/domain/entities/level.dart';
import '../viewmodels/level_list_view_model.dart';

class LevelListPage extends StatefulWidget {
  const LevelListPage({super.key});

  @override
  State<LevelListPage> createState() => _LevelListPageState();
}

class _LevelListPageState extends State<LevelListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LevelListViewModel>().loadLevels();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LevelListViewModel>();

    final filtered = viewModel.levels
        .where((l) => l.code.toLowerCase().contains(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: LexiaAppBar(
        actions: [
          LexiaAppBarIconButton(
            icon: Icons.refresh_rounded,
            tooltip: viewModel.reloadProgress ?? 'Reload vocabulary',
            isLoading: viewModel.isReloading,
            onPressed: viewModel.reloadLevels,
          ),
        ],
      ),
      body: _buildBody(context, viewModel, filtered),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LevelListViewModel viewModel,
    List<Level> filtered,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GOOD MORNING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.light,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Learner',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                _StreakCard(viewModel: viewModel),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SearchBar(
              controller: _searchController,
              hint: 'Search level...',
            ),
          ),
        ),

        if (viewModel.isReloading && viewModel.reloadProgress != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.circular(AppDecorations.radiusMd),
                  boxShadow: AppDecorations.shadowSm,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.greenMid,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        viewModel.reloadProgress!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (viewModel.errorMessage != null && viewModel.levels.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: AppErrorBanner(message: viewModel.errorMessage!),
            ),
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _CreateExamButton(
              onTap: () => context
                  .read<AppNavigationNotifier>()
                  .openHomeRoute(HomeRoutePaths.examConfig),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: const Text(
              'Your Levels',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ),

        if (viewModel.isLoading && viewModel.levels.isEmpty)
          const SliverFillRemaining(
            child: AppLoading(message: 'Loading levels...'),
          )
        else if (viewModel.errorMessage != null && viewModel.levels.isEmpty)
          SliverFillRemaining(
            child: AppErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.loadLevels,
            ),
          )
        else if (filtered.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No levels found.',
                style: TextStyle(color: AppColors.light),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final level = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LevelCard(
                      level: level,
                      colorIndex: index,
                      onTap: () {
                        context
                            .read<AppNavigationNotifier>()
                            .openHomeRoute(
                              HomeRoutePaths.unitList,
                              params: {'level': level.code},
                            );
                      },
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.viewModel});

  final LevelListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final streakLabel = viewModel.currentStreak == 1
        ? '1 day'
        : '${viewModel.currentStreak} days';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.greenMid,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        boxShadow: AppDecorations.shadowMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 15, color: AppColors.coral),
                    SizedBox(width: 4),
                    Text(
                      'Current Streak',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  streakLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          _MiniStat(
            icon: Icons.check,
            value: '${viewModel.totalLearned}',
            label: 'Learned',
            color: AppColors.green,
          ),
          const SizedBox(width: 20),
          _MiniStat(
            icon: Icons.star,
            value: '${viewModel.totalStarred}',
            label: 'Starred',
            color: AppColors.coral,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.light, fontSize: 14),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.light, size: 20),
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          borderSide:
              const BorderSide(color: AppColors.greenMid, width: 1.5),
        ),
      ),
    );
  }
}

class _CreateExamButton extends StatelessWidget {
  const _CreateExamButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppDecorations.pillButton(AppColors.coralDark),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Create Exam',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.colorIndex,
    required this.onTap,
  });

  final Level level;
  final int colorIndex;
  final VoidCallback onTap;

  String _subtitle(String code) {
    final c = code.toLowerCase();
    if (c.contains('a1')) return 'Beginner';
    if (c.contains('a2')) return 'Elementary';
    if (c.contains('b1')) return 'Intermediate';
    if (c.contains('b2')) return 'Upper Intermediate';
    if (c.contains('c')) return 'Advanced';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.levelPalette(colorIndex);
    final pct = (level.progress * 100).round();
    final left = level.totalTerms - level.knownTerms;
    final subtitle = _subtitle(level.code);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.withAlpha33(pal.bg),
          borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
          border: Border.all(color: pal.accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.code.toUpperCase().replaceAll('&', ' & '),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mid,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pal.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: pal.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: level.progress,
                minHeight: 6,
                backgroundColor: AppColors.white.withValues(alpha: 0.7),
                valueColor: AlwaysStoppedAnimation<Color>(pal.accent),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatCol(
                  icon: Icons.check,
                  iconColor: pal.accent,
                  value: '${level.knownTerms}',
                  label: 'Learned',
                ),
                const SizedBox(width: 22),
                _StatCol(
                  icon: Icons.crop_square_outlined,
                  iconColor: AppColors.light,
                  value: '$left',
                  label: 'Left',
                ),
                const SizedBox(width: 22),
                _StatCol(
                  icon: Icons.library_books_outlined,
                  iconColor: AppColors.light,
                  value: '${level.totalTerms}',
                  label: 'Total',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.light),
        ),
      ],
    );
  }
}
