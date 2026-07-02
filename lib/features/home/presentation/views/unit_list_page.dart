import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../../../shared/vocabulary/domain/entities/unit.dart';
import '../viewmodels/unit_list_view_model.dart';

enum _SortMode { original, az, za }

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

    final overallProgress = vm.units.isEmpty
        ? 0.0
        : vm.units.fold(0, (s, u) => s + u.knownTerms) /
            (vm.units.fold(0, (s, u) => s + u.totalTerms).clamp(1, 999999));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const LexiaAppBar(showBack: true),
      body: CustomScrollView(
        slivers: [
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
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${vm.units.length} units · $totalTerms words',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.light,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: overallProgress,
                      minHeight: 7,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.greenMid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SearchBarWidget(
                controller: _searchController,
                hint: 'Search units...',
              ),
            ),
          ),

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
                      color: AppColors.ink,
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
                child: Text(
                  'No units found.',
                  style: TextStyle(color: AppColors.light),
                ),
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

class _IndexedUnit {
  const _IndexedUnit({required this.index, required this.unit});
  final int index;
  final Unit unit;
}

class _SearchBarWidget extends StatelessWidget {
  const _SearchBarWidget(
      {required this.controller, required this.hint});

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
          color: selected ? AppColors.greenDark : AppColors.white,
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          border: Border.all(
            color: selected ? AppColors.greenDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.mid,
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.displayIndex,
    required this.onTap,
  });

  final Unit unit;
  final int displayIndex;
  final VoidCallback onTap;

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
    final pal = AppColors.unitPalette(displayIndex);
    final icon = _icons[displayIndex % _icons.length];
    final pct = (unit.progress * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          boxShadow: AppDecorations.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pal.bg,
                    borderRadius:
                        BorderRadius.circular(AppDecorations.radiusSm),
                  ),
                  child: Icon(icon, color: pal.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit ${displayIndex + 1}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        unit.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mid,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: pal.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: unit.progress,
                minHeight: 5,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(pal.accent),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check, size: 13, color: AppColors.light),
                const SizedBox(width: 3),
                Text(
                  '${unit.knownTerms} learned',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.light,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.crop_square_outlined,
                    size: 13, color: AppColors.light),
                const SizedBox(width: 3),
                Text(
                  '${unit.totalTerms} total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.light,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
