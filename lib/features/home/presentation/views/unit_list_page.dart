import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../../../shared/vocabulary/domain/entities/unit.dart';
import '../viewmodels/unit_list_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sort options
// ─────────────────────────────────────────────────────────────────────────────

enum _SortMode { original, az, za }

// ─────────────────────────────────────────────────────────────────────────────
// Page entry point — owns ViewModel lifecycle
// ─────────────────────────────────────────────────────────────────────────────

class UnitListPage extends StatefulWidget {
  const UnitListPage({super.key, required this.levelCode});

  final String levelCode;

  @override
  State<UnitListPage> createState() => _UnitListPageState();
}

class _UnitListPageState extends State<UnitListPage> {
  late final UnitListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UnitListViewModel(levelCode: widget.levelCode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadUnits();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UnitListViewModel>.value(
      value: _viewModel,
      child: const _UnitListView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View (stateful for search + sort local state)
// ─────────────────────────────────────────────────────────────────────────────

class _UnitListView extends StatefulWidget {
  const _UnitListView();

  @override
  State<_UnitListView> createState() => _UnitListViewState();
}

class _UnitListViewState extends State<_UnitListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortMode _sort = _SortMode.original;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _levelSubtitle(String code) {
    final c = code.toLowerCase();
    if (c.contains('a1')) return 'Beginner';
    if (c.contains('a2')) return 'Elementary';
    if (c.contains('b1')) return 'Intermediate';
    if (c.contains('b2')) return 'Upper Intermediate';
    if (c.contains('c')) return 'Advanced';
    return '';
  }

  List<_IndexedUnit> _processUnits(List<Unit> units) {
    // Build indexed list first (Unit 1, Unit 2...)
    final indexed = units
        .asMap()
        .entries
        .map((e) => _IndexedUnit(index: e.key, unit: e.value))
        .where((u) =>
            u.unit.name.toLowerCase().contains(_searchQuery))
        .toList();

    switch (_sort) {
      case _SortMode.original:
        return indexed;
      case _SortMode.az:
        return indexed..sort((a, b) => a.unit.name.compareTo(b.unit.name));
      case _SortMode.za:
        return indexed..sort((a, b) => b.unit.name.compareTo(a.unit.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UnitListViewModel>();
    final levelCode = vm.levelCode;
    final subtitle = _levelSubtitle(levelCode);
    final totalTerms = vm.units.fold(0, (s, u) => s + u.totalTerms);
    final processedUnits = _processUnits(vm.units);

    // Overall progress
    final overallProgress = vm.units.isEmpty
        ? 0.0
        : vm.units.fold(0, (s, u) => s + u.knownTerms) /
            (vm.units.fold(0, (s, u) => s + u.totalTerms).clamp(1, 999999));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FA),
      appBar: const LexiaAppBar(showBack: true),
      body: CustomScrollView(
        slivers: [
          // ── Page header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle.isNotEmpty
                        ? '${levelCode.toUpperCase()} — $subtitle'
                        : levelCode.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${vm.units.length} units · $totalTerms words',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 14),
                  // Full blue progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SearchBarWidget(
                controller: _searchController,
                hint: 'Search units...',
              ),
            ),
          ),

          // ── Sort chips ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sort',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _SortChip(
                        label: 'Original order',
                        selected: _sort == _SortMode.original,
                        onTap: () =>
                            setState(() => _sort = _SortMode.original),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'A–Z',
                        selected: _sort == _SortMode.az,
                        onTap: () =>
                            setState(() => _sort = _SortMode.az),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        label: 'Z–A',
                        selected: _sort == _SortMode.za,
                        onTap: () =>
                            setState(() => _sort = _SortMode.za),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          if (vm.isLoading)
            const SliverFillRemaining(
              child: AppLoading(message: 'Loading units...'),
            )
          else if (vm.errorMessage != null)
            SliverFillRemaining(
              child: AppErrorView(
                message: vm.errorMessage!,
                onRetry: vm.loadUnits,
              ),
            )
          else if (processedUnits.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No units found.',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final item = processedUnits[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UnitCard(
                        unit: item.unit,
                        displayIndex: item.index,
                        onTap: () {
                          context
                              .read<AppNavigationNotifier>()
                              .openHomeRoute(
                                HomeRoutePaths.termList,
                                params: {
                                  'level': vm.levelCode,
                                  'unit': item.unit.name,
                                  'unitId': item.unit.id,
                                },
                              );
                        },
                      ),
                    );
                  },
                  childCount: processedUnits.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _IndexedUnit {
  const _IndexedUnit({required this.index, required this.unit});
  final int index;
  final Unit unit;
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar widget
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBarWidget extends StatelessWidget {
  const _SearchBarWidget(
      {required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFBCC0CC), fontSize: 14),
        prefixIcon:
            const Icon(Icons.search, color: Color(0xFFBCC0CC), size: 20),
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
// Sort chip
// ─────────────────────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unit card
// ─────────────────────────────────────────────────────────────────────────────

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.displayIndex,
    required this.onTap,
  });

  final Unit unit;
  final int displayIndex;
  final VoidCallback onTap;

  static const _palettes = [
    _UnitPalette(
        iconBg: Color(0xFFDBEAFE),
        iconColor: Color(0xFF3B82F6),
        progress: Color(0xFF3B82F6),
        pct: Color(0xFF3B82F6)),
    _UnitPalette(
        iconBg: Color(0xFFFEE2E2),
        iconColor: Color(0xFFEF4444),
        progress: Color(0xFFEF4444),
        pct: Color(0xFFEF4444)),
    _UnitPalette(
        iconBg: Color(0xFFFEF3C7),
        iconColor: Color(0xFFF59E0B),
        progress: Color(0xFFF59E0B),
        pct: Color(0xFFF59E0B)),
    _UnitPalette(
        iconBg: Color(0xFFD1FAE5),
        iconColor: Color(0xFF10B981),
        progress: Color(0xFF10B981),
        pct: Color(0xFF10B981)),
    _UnitPalette(
        iconBg: Color(0xFFEDE9FE),
        iconColor: Color(0xFF8B5CF6),
        progress: Color(0xFF8B5CF6),
        pct: Color(0xFF8B5CF6)),
    _UnitPalette(
        iconBg: Color(0xFFDBEAFE),
        iconColor: Color(0xFF60A5FA),
        progress: Color(0xFF60A5FA),
        pct: Color(0xFF60A5FA)),
  ];

  static const _icons = [
    Icons.flight_takeoff_outlined,
    Icons.work_outline_rounded,
    Icons.favorite_border_rounded,
    Icons.computer_outlined,
    Icons.eco_outlined,
    Icons.palette_outlined,
    Icons.science_outlined,
    Icons.home_outlined,
    Icons.music_note_outlined,
    Icons.directions_run_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final pal = _palettes[displayIndex % _palettes.length];
    final icon = _icons[displayIndex % _icons.length];
    final pct = (unit.progress * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pal.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: pal.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit ${displayIndex + 1}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        unit.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Percentage
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: pal.pct,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: unit.progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor:
                    AlwaysStoppedAnimation<Color>(pal.progress),
              ),
            ),
            const SizedBox(height: 10),
            // Stats
            Row(
              children: [
                Icon(Icons.check, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 3),
                Text(
                  '${unit.knownTerms} learned',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 14),
                Icon(Icons.crop_square_outlined,
                    size: 13, color: Colors.grey[400]),
                const SizedBox(width: 3),
                Text(
                  '${unit.totalTerms} total',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitPalette {
  const _UnitPalette({
    required this.iconBg,
    required this.iconColor,
    required this.progress,
    required this.pct,
  });

  final Color iconBg;
  final Color iconColor;
  final Color progress;
  final Color pct;
}
