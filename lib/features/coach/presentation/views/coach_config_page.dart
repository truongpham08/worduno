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
import '../../domain/entities/coach_star_filter.dart';
import '../viewmodels/coach_config_view_model.dart';

class CoachConfigPage extends StatefulWidget {
  const CoachConfigPage({
    super.key,
    this.levelCode,
    this.unitName,
    this.unitId,
  });

  final String? levelCode;
  final String? unitName;
  final String? unitId;

  @override
  State<CoachConfigPage> createState() => _CoachConfigPageState();
}

class _CoachConfigPageState extends State<CoachConfigPage> {
  late final CoachConfigViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CoachConfigViewModel(
      levelCode: widget.levelCode,
      unitName: widget.unitName,
      unitId: widget.unitId,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _onStart(BuildContext context) async {
    try {
      await _viewModel.startSession();
      if (!context.mounted) return;
      context.read<AppNavigationNotifier>().openHomeRoute(
            HomeRoutePaths.coachSession,
          );
    } catch (_) {
      // Error shown via view model.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoachConfigViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: const WordunoAppBar(title: 'AI Coach'),
        body: Consumer<CoachConfigViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const AppLoading(message: 'Loading coach options...');
            }
            if (vm.initErrorMessage != null) {
              return AppErrorView(
                message: vm.initErrorMessage!,
                onRetry: vm.reload,
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (vm.isUnitScoped) ...[
                  _InfoCard(
                    icon: Icons.book_outlined,
                    title: widget.unitName ?? '',
                    subtitle: (widget.levelCode ?? '').toUpperCase(),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _SectionTitle('Levels'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChoiceChip(
                        label: 'All levels',
                        selected: vm.allLevelsSelected,
                        onTap: vm.selectAllLevels,
                      ),
                      for (final level in vm.levels)
                        _ChoiceChip(
                          label: level.code.toUpperCase(),
                          selected: !vm.allLevelsSelected &&
                              vm.selectedLevelCodes.contains(level.code),
                          onTap: () => vm.toggleLevel(level.code),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('Unit'),
                  const SizedBox(height: 10),
                  _DropdownField<String?>(
                    value: vm.allUnitsSelected ? null : vm.selectedUnitKey,
                    hint: 'All units',
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All units'),
                      ),
                      for (final unit in vm.unitOptions)
                        DropdownMenuItem<String?>(
                          value: unit.key,
                          child: Text(unit.label),
                        ),
                    ],
                    onChanged: vm.selectUnit,
                  ),
                  const SizedBox(height: 24),
                ],
                _SectionTitle('Word filter'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CoachStarFilter.values.map((filter) {
                    return _ChoiceChip(
                      label: filter.label,
                      selected: vm.starFilter == filter,
                      onTap: () => vm.setStarFilter(filter),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                _SectionTitle('Word count'),
                const SizedBox(height: 6),
                if (vm.isPoolCountLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(
                      color: AppColors.coralMid,
                      backgroundColor: AppColors.border,
                    ),
                  )
                else
                  Text(
                    vm.availableWordCount == 0
                        ? 'No words available for the current filters.'
                        : '${vm.availableWordCount} words available • select 1–${vm.availableWordCount}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mid,
                    ),
                  ),
                if (vm.poolCountError != null) ...[
                  const SizedBox(height: 8),
                  AppErrorBanner(message: vm.poolCountError!),
                  TextButton(
                    onPressed: vm.isPoolCountLoading ? null : vm.retryPoolCount,
                    child: const Text('Retry word count'),
                  ),
                ],
                const SizedBox(height: 12),
                if (vm.availableWordCount > 0) ...[
                  Row(
                    children: [
                      IconButton(
                        onPressed: vm.wordCount > 1
                            ? () => vm.setWordCount(vm.wordCount - 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.coralMid,
                      ),
                      Expanded(
                        child: Slider(
                          value: vm.wordCount.toDouble(),
                          min: 1,
                          max: vm.availableWordCount.toDouble(),
                          divisions: vm.availableWordCount > 1
                              ? vm.availableWordCount - 1
                              : 1,
                          activeColor: AppColors.coralMid,
                          label: '${vm.wordCount}',
                          onChanged: (v) => vm.setWordCount(v.round()),
                        ),
                      ),
                      IconButton(
                        onPressed: vm.wordCount < vm.availableWordCount
                            ? () => vm.setWordCount(vm.wordCount + 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.coralMid,
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      '${vm.wordCount} words',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.coralDark,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                _StartButton(
                  loading: vm.isStarting,
                  enabled: vm.availableWordCount > 0 &&
                      !vm.isStarting &&
                      !vm.isPoolCountLoading,
                  onTap: () => _onStart(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.beigeLight,
              borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            ),
            child: Icon(icon, color: AppColors.greenMid),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            color: selected ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? AppColors.coralDark : AppColors.light,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.coralDark.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
            onTap: enabled && !loading ? onTap : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_toy_rounded, color: AppColors.white),
                        SizedBox(width: 8),
                        Text(
                          'Start Coach Session',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
