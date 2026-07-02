import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../domain/entities/coach_entities.dart';
import '../viewmodels/coach_history_view_model.dart';

class CoachHistoryPage extends StatefulWidget {
  const CoachHistoryPage({super.key});

  @override
  State<CoachHistoryPage> createState() => _CoachHistoryPageState();
}

class _CoachHistoryPageState extends State<CoachHistoryPage> {
  late final CoachHistoryViewModel _viewModel;
  AppNavigationNotifier? _navigationNotifier;

  @override
  void initState() {
    super.initState();
    _viewModel = CoachHistoryViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadTerms();
      _navigationNotifier = context.read<AppNavigationNotifier>();
      _navigationNotifier!.addListener(_onNavigationChanged);
    });
  }

  void _onNavigationChanged() {
    final config = _navigationNotifier?.configuration;
    if (config == null) return;
    if (config.tab == AppTab.coachHistory && config.coachStack.length == 1) {
      _viewModel.loadTerms();
    }
  }

  @override
  void dispose() {
    _navigationNotifier?.removeListener(_onNavigationChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoachHistoryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2FA),
        appBar: const WordunoAppBar(title: 'AI History', showBack: false),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.read<AppNavigationNotifier>().startCoachFromHistory();
          },
          backgroundColor: const Color(0xFF8B5CF6),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(
            'Start Coach',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: Consumer<CoachHistoryViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const AppLoading(message: 'Loading history...');
            }
            if (vm.errorMessage != null) {
              return AppErrorView(
                message: vm.errorMessage!,
                onRetry: vm.loadTerms,
              );
            }
            if (vm.terms.isEmpty) {
              return _EmptyHistory(
                onStart: () {
                  context.read<AppNavigationNotifier>().startCoachFromHistory();
                },
              );
            }
            return RefreshIndicator(
              onRefresh: vm.loadTerms,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                itemCount: vm.terms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final term = vm.terms[index];
                  return _TermCard(
                    term: term,
                    onTap: () {
                      context.read<AppNavigationNotifier>().openCoachTermDetail(
                            unitId: term.unitId,
                            termId: term.termId,
                          );
                    },
                    onDelete: () => _confirmDeleteTerm(context, vm, term),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTerm(
    BuildContext context,
    CoachHistoryViewModel vm,
    CoachHistoryTerm term,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all feedback?'),
        content: Text(
          'Remove all coaching feedback for "${term.word}"? Explanation will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await vm.deleteAllFeedbacks(term);
    }
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 36,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No coach history yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coached words appear here with level and unit. Each term is tracked separately.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Start Coach',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.term,
    required this.onTap,
    required this.onDelete,
  });

  final CoachHistoryTerm term;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.word,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${term.levelCode.toUpperCase()} · ${term.unitName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      term.definition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${CoachHistoryViewModel.formatDateTime(term.lastCoachedAt)} · ${term.feedbackCount} feedback',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFF9CA3AF),
                onPressed: onDelete,
                tooltip: 'Delete all feedback',
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
