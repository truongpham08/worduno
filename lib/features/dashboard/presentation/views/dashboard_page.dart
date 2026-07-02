import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../../domain/entities/dashboard_data.dart';

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
      backgroundColor: const Color(0xFFF0F2FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lexia',
          style: TextStyle(
            color: Color(0xFF3B82F6),
            fontWeight: FontWeight.w800,
            fontSize: 20,
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
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF3B82F6),
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
                    iconBg: const Color(0xFFD1FAE5),
                    iconColor: const Color(0xFF10B981),
                    value: '${data.learnedWordsCount}',
                    label: 'learned',
                    textColor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.auto_stories_rounded,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFF59E0B),
                    value: '${data.learningWordsCount}',
                    label: 'learning',
                    textColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStatCard(
                    icon: Icons.star_rounded,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFEF4444),
                    value: '${data.starredWordsCount}',
                    label: 'starred',
                    textColor: const Color(0xFFEF4444),
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
                    iconColor: const Color(0xFF3B82F6),
                    value: '${data.examCount}',
                    label: 'exam count',
                    cardBg: const Color(0xFFEEF3FE),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ExamStatCard(
                    icon: Icons.bookmark_added_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    value: '${(data.averageExamScore * 100).round()}%',
                    label: 'avg exam score',
                    cardBg: const Color(0xFFEDE9FE),
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
                    iconColor: const Color(0xFF10B981),
                    units: data.strongestUnits,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StrengthWeaknessCol(
                    title: 'Weakest',
                    icon: Icons.error_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
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

// -----------------------------------------------------------------------------
// Custom Widgets & Sub-views
// -----------------------------------------------------------------------------

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
        Icon(icon, size: 18, color: const Color(0xFF374151)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
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
                color: Color(0xFF3B82F6),
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: Color(0xFF3B82F6),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Overall Progress Card (circular canvas)
// -----------------------------------------------------------------------------

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                backgroundColor: const Color(0xFFE5E7EB),
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
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
                    color: Color(0xFF9CA3AF),
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
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      ' / $total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
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
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'words learned across all levels',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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
    required this.gradient,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Gradient gradient;
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
      ..shader = gradient.createShader(rect)
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
        oldDelegate.gradient != gradient ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

// -----------------------------------------------------------------------------
// Mini Statistics Cards (Row: Learned, Learning, Starred)
// -----------------------------------------------------------------------------

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.textColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Exam Stat Cards (Exam Count, Average Score)
// -----------------------------------------------------------------------------

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
        borderRadius: BorderRadius.circular(16),
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
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
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

// -----------------------------------------------------------------------------
// Level Progress Row Cards
// -----------------------------------------------------------------------------

class _LevelProgressRowCard extends StatelessWidget {
  const _LevelProgressRowCard({required this.level});

  final LevelProgressData level;

  Color _getLevelColor(String code) {
    final c = code.toLowerCase();
    if (c.contains('b1')) return const Color(0xFF3B82F6);
    if (c.contains('b2')) return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B); // C1&C2
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _getLevelColor(level.levelCode);
    final percentage = (level.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                level.levelName,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
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
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${level.knownTerms} / ${level.totalTerms} words',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Strongest / Weakest Columns Grid
// -----------------------------------------------------------------------------

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (units.isEmpty)
            const Text(
              'No data yet',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            )
          else
            Column(
              children: units.map((unit) {
                final pct = (unit.progress * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      // Mini circle icon
                      _UnitMiniBadge(unitId: unit.unitId),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unit ${unit.unitId}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
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

  Color _getBadgeColor(String id) {
    final val = int.tryParse(id) ?? 0;
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
    ];
    return colors[val % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor(unitId);

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

// -----------------------------------------------------------------------------
// Recent Exam Card
// -----------------------------------------------------------------------------

class _RecentExamCard extends StatelessWidget {
  const _RecentExamCard({required this.exam});

  final RecentExamItem exam;

  Color _getCircleColor(double score) {
    if (score >= 0.8) return const Color(0xFF10B981); // Green
    if (score >= 0.6) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  Color _getCircleBg(double score) {
    if (score >= 0.8) return const Color(0xFFD1FAE5);
    if (score >= 0.6) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  @override
  Widget build(BuildContext context) {
    final scorePct = (exam.score * 100).round();
    final circleBg = _getCircleBg(exam.score);
    final circleFg = _getCircleColor(exam.score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score badge circle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$scorePct%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: circleFg,
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
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${exam.dateLabel} - ${exam.questionCount} questions',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
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

// -----------------------------------------------------------------------------
// Recent AI Coach Card
// -----------------------------------------------------------------------------

class _RecentCoachCard extends StatelessWidget {
  const _RecentCoachCard({required this.coach});

  final RecentCoachItem coach;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                coach.word,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 6),
              // Stars
              Row(
                children: List.generate(5, (index) {
                  final filled = index < coach.rating;
                  return Icon(
                    Icons.star_rounded,
                    size: 13.5,
                    color: filled
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFE5E7EB),
                  );
                }),
              ),
              const Spacer(),
              Text(
                coach.dateLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '"${coach.sentence}"',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF4B5563),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
