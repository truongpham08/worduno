import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../../application/models/dashboard_data.dart';

class DashboardPage extends StatefulWidget {
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
    final viewModel = context.watch<DashboardViewModel>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.greenDark,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Lexia',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, DashboardViewModel viewModel) {
    if (viewModel.isLoading && viewModel.data == null) {
      return const AppLoading(message: 'Loading stats...');
    }

    if (viewModel.errorMessage != null) {
      return AppErrorView(
        message: viewModel.errorMessage!,
        onRetry: () => viewModel.loadDashboardData(),
      );
    }

    final data = viewModel.data;
    if (data == null) {
      return const Center(child: Text('No stats available.'));
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title row
            Row(
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.greenDark,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // OVERALL PROGRESS CARD
            _OverallProgressCard(
              progress: data.overallProgress,
              learned: data.learnedWordsCount,
              total: data.totalTerms,
            ),
            const SizedBox(height: 14),

            // STATS CARD GRID (3 columns: Learned, Learning, Starred)
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.check_circle_rounded,
                    cardBg: AppColors.green,
                    iconColor: AppColors.greenDark,
                    value: '${data.learnedWordsCount}',
                    label: 'learned',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.auto_stories_rounded,
                    cardBg: AppColors.beigeLight,
                    iconColor: AppColors.coralMid,
                    value: '${data.learningWordsCount}',
                    label: 'learning',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.star_rounded,
                    cardBg: AppColors.coral,
                    iconColor: AppColors.coralDark,
                    value: '${data.starredWordsCount}',
                    label: 'starred',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // EXAM STATS ROW (2 columns: Exam Count, Avg Score)
            Row(
              children: [
                Expanded(
                  child: _ExamStatCard(
                    icon: Icons.description_rounded,
                    iconColor: AppColors.greenMid,
                    value: '${data.examCount}',
                    label: 'exam count',
                    cardBg: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ExamStatCard(
                    icon: Icons.bookmark_added_rounded,
                    iconColor: AppColors.greenDark,
                    value: '${(data.averageExamScore * 100).round()}%',
                    label: 'avg exam score',
                    cardBg: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // LEVEL PROGRESS SECTION
            _SectionHeader(
              title: 'Level Progress',
              icon: Icons.explore_outlined,
            ),
            const SizedBox(height: 10),
            Column(
              children: data.levelProgressList.map((level) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LevelProgressRowCard(level: level),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // STRONGEST & WEAKEST SPLIT ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StrengthWeaknessCol(
                    title: 'Strongest',
                    icon: Icons.emoji_events_outlined,
                    iconColor: AppColors.greenDark,
                    units: data.strongestUnits,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StrengthWeaknessCol(
                    title: 'Weakest',
                    icon: Icons.error_outline_rounded,
                    iconColor: AppColors.coralDark,
                    units: data.weakestUnits,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // RECENT EXAMS FEED
            _SectionHeader(
              title: 'Recent Exams',
              icon: Icons.history_rounded,
              trailing: _ViewAllButton(
                onTap: () => context.read<AppNavigationNotifier>().selectTab(
                  AppTab.examHistory,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (data.recentExams.isEmpty)
              const _EmptyStateView(message: 'No exams taken yet.')
            else
              Column(
                children: data.recentExams.map((exam) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentExamCard(exam: exam),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // RECENT AI COACH FEED
            _SectionHeader(
              title: 'Recent AI Coach',
              icon: Icons.smart_toy_outlined,
              trailing: _ViewAllButton(
                onTap: () => context.read<AppNavigationNotifier>().selectTab(
                  AppTab.coachHistory,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (data.recentCoachFeedback.isEmpty)
              const _EmptyStateView(message: 'No AI Coach chats yet.')
            else
              Column(
                children: data.recentCoachFeedback.map((coach) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentCoachCard(coach: coach),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Custom Widgets & Sub-views
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mid),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View all',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.greenDark,
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: AppColors.greenDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.light, fontSize: 13),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Overall Progress Card (circular canvas)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({
    required this.progress,
    required this.learned,
    required this.total,
  });

  final double progress;
  final int learned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.beigeLight,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Row(
        children: [
          // Circular Arc Canvas
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: progress,
                strokeWidth: 8,
                color: AppColors.greenDark,
                backgroundColor: AppColors.border,
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),

          // Details side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OVERALL PROGRESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.light,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$learned',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      ' / $total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.light,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Tiny linear progress below numbers
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.greenDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'words learned across all levels',
                  style: TextStyle(fontSize: 11, color: AppColors.mid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = -3.1415926535 / 2;
    final sweepAngle = 2 * 3.1415926535 * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Mini Statistics Cards (Row: Learned, Learning, Starred)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.cardBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color cardBg;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Exam Stat Cards (Exam Count, Average Score)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ExamStatCard extends StatelessWidget {
  const _ExamStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.cardBg,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color cardBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Level Progress Row Cards
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LevelProgressRowCard extends StatelessWidget {
  const _LevelProgressRowCard({required this.level});

  final LevelProgressData level;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.levelPaletteForCode(level.levelCode);
    final barColor = palette.accent;
    final percentage = (level.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                level.levelCode.toUpperCase().replaceAll('&', ' & '),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                level.levelName,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mid,
                ),
              ),
              const Spacer(),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: level.progress,
              minHeight: 6,
              backgroundColor: palette.bg,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${level.knownTerms} / ${level.totalTerms} words',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.light,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Strongest / Weakest Columns Grid
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StrengthWeaknessCol extends StatelessWidget {
  const _StrengthWeaknessCol({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.units,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<UnitProgressData> units;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (units.isEmpty)
            const Text(
              'No data yet',
              style: TextStyle(fontSize: 11, color: AppColors.light),
            )
          else
            Column(
              children: units.map((unit) {
                final pct = (unit.progress * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _UnitMiniBadge(unitId: unit.unitId),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              unit.unitName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mid,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppDecorations.radiusPill,
                        ),
                        child: LinearProgressIndicator(
                          value: unit.progress,
                          minHeight: 4,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _UnitMiniBadge extends StatelessWidget {
  const _UnitMiniBadge({required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context) {
    final val = int.tryParse(unitId) ?? 0;
    final color = AppColors.unitPalette(val).accent;

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3.5),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Recent Exam Card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RecentExamCard extends StatelessWidget {
  const _RecentExamCard({required this.exam});

  final RecentExamItem exam;

  @override
  Widget build(BuildContext context) {
    final scorePct = (exam.score * 100).round();
    final scorePalette = AppColors.examScore(exam.score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          // Score badge circle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scorePalette.bg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$scorePct%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: scorePalette.fg,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.unitName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${exam.dateLabel} · ${exam.questionCount} questions',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.light,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Recent AI Coach Card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RecentCoachCard extends StatelessWidget {
  const _RecentCoachCard({required this.coach});

  final RecentCoachItem coach;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coach.word,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                coach.dateLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.light,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatQuotedSentence(coach.sentence),
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.mid,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatQuotedSentence(String sentence) {
  final cleaned = sentence
      .replaceAll(RegExp(r'^["\u201c\u201d]+|["\u201c\u201d]+$'), '')
      .trim();

  return '"$cleaned"';
}
