import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
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
      backgroundColor: const Color(0xFFF0F2FA),
      appBar: const LexiaAppBar(),
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
        // ── Greeting + Streak ──────────────────────────────────────────
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
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Learner',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                _StreakCard(),
              ],
            ),
          ),
        ),

        // ── Search ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SearchBar(
              controller: _searchController,
              hint: 'Search level...',
            ),
          ),
        ),

        // ── Create Exam button ──────────────────────────────────────────
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

        // ── "Your Levels" label ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Your Levels',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),

        // ── Content ────────────────────────────────────────────────────
        if (viewModel.isLoading)
          const SliverFillRemaining(
            child: AppLoading(message: 'Loading levels...'),
          )
        else if (viewModel.errorMessage != null)
          SliverFillRemaining(
            child: AppErrorView(
              message: viewModel.errorMessage!,
              onRetry: viewModel.loadLevels,
            ),
          )
        else if (filtered.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('No levels found.',
                  style: TextStyle(color: Colors.grey)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Streak card
// ─────────────────────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 15, color: Colors.orange[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Current Streak',
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  '0 days',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          _MiniStat(
            icon: Icons.check,
            value: '0',
            label: 'Learned',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 20),
          _MiniStat(
            icon: Icons.star,
            value: '0',
            label: 'Starred',
            color: const Color(0xFFF59E0B),
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
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon:
            Icon(Icons.search, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Exam gradient button
// ─────────────────────────────────────────────────────────────────────────────

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
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFAB47BC)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Create Exam',
              style: TextStyle(
                color: Colors.white,
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

// ─────────────────────────────────────────────────────────────────────────────
// Level card
// ─────────────────────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.colorIndex,
    required this.onTap,
  });

  final Level level;
  final int colorIndex;
  final VoidCallback onTap;

  static const _palette = [
    _LevelPalette(
      bg: Color(0xFFEEF3FE),
      progressColor: Color(0xFF3B82F6),
      badgeText: Color(0xFF3B82F6),
      badgeBg: Color(0xFFDBEAFE),
      statIcon: Color(0xFF3B82F6),
    ),
    _LevelPalette(
      bg: Color(0xFFFEEEEE),
      progressColor: Color(0xFFEF4444),
      badgeText: Color(0xFFEF4444),
      badgeBg: Color(0xFFFEE2E2),
      statIcon: Color(0xFFEF4444),
    ),
    _LevelPalette(
      bg: Color(0xFFFEFBE6),
      progressColor: Color(0xFFF59E0B),
      badgeText: Color(0xFFF59E0B),
      badgeBg: Color(0xFFFEF3C7),
      statIcon: Color(0xFFF59E0B),
    ),
    _LevelPalette(
      bg: Color(0xFFEEFBF3),
      progressColor: Color(0xFF10B981),
      badgeText: Color(0xFF10B981),
      badgeBg: Color(0xFFD1FAE5),
      statIcon: Color(0xFF10B981),
    ),
  ];

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
    final pal = _palette[colorIndex % _palette.length];
    final pct = (level.progress * 100).round();
    final left = level.totalTerms - level.knownTerms;
    final subtitle = _subtitle(level.code);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pal.bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
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
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pal.badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: pal.badgeText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: level.progress,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.7),
                valueColor:
                    AlwaysStoppedAnimation<Color>(pal.progressColor),
              ),
            ),
            const SizedBox(height: 14),
            // Stats row: Learned | Left | Total
            Row(
              children: [
                _StatCol(
                  icon: Icons.check,
                  iconColor: pal.statIcon,
                  value: '${level.knownTerms}',
                  label: 'Learned',
                ),
                const SizedBox(width: 22),
                _StatCol(
                  icon: Icons.crop_square_outlined,
                  iconColor: Colors.grey[500]!,
                  value: '$left',
                  label: 'Left',
                ),
                const SizedBox(width: 22),
                _StatCol(
                  icon: Icons.library_books_outlined,
                  iconColor: Colors.grey[500]!,
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

class _LevelPalette {
  const _LevelPalette({
    required this.bg,
    required this.progressColor,
    required this.badgeText,
    required this.badgeBg,
    required this.statIcon,
  });

  final Color bg;
  final Color progressColor;
  final Color badgeText;
  final Color badgeBg;
  final Color statIcon;
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
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
