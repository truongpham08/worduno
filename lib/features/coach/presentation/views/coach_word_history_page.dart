import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../domain/entities/coach_entities.dart';
import '../viewmodels/coach_history_view_model.dart';
import 'coach_explain_section.dart';

class CoachWordHistoryPage extends StatefulWidget {
  const CoachWordHistoryPage({
    super.key,
    required this.unitId,
    required this.termId,
  });

  final String unitId;
  final String termId;

  @override
  State<CoachWordHistoryPage> createState() => _CoachWordHistoryPageState();
}

class _CoachWordHistoryPageState extends State<CoachWordHistoryPage> {
  late final CoachWordHistoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CoachWordHistoryViewModel(
      unitId: widget.unitId,
      termId: widget.termId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.load());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _deleteAllFeedbacks(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all feedback?'),
        content: const Text(
          'Remove all coaching feedback for this term? Explanation will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _viewModel.deleteAllFeedbacks();
      if (context.mounted && _viewModel.feedbacks.isEmpty) {
        context.read<AppNavigationNotifier>().popCoachRoute();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoachWordHistoryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: WordunoAppBar(
          title: 'Word Coach',
          actions: [
            Consumer<CoachWordHistoryViewModel>(
              builder: (context, vm, _) {
                if (vm.feedbacks.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete all feedback',
                  onPressed: () => _deleteAllFeedbacks(context),
                );
              },
            ),
          ],
        ),
        body: Consumer<CoachWordHistoryViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const AppLoading(message: 'Loading word...');
            }
            if (vm.errorMessage != null || vm.term == null) {
              return AppErrorView(
                message: vm.errorMessage ?? 'Term not found.',
                onRetry: vm.load,
              );
            }

            final term = vm.term!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _WordHeader(term: term),
                const SizedBox(height: 16),
                if (term.explanation != null)
                  CoachExplainSection(result: term.explanation!)
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.card(),
                    child: const Text(
                      'No explanation saved for this term yet.',
                      style: TextStyle(color: AppColors.mid),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Coaching feedback',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                if (vm.feedbacks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.card(),
                    child: const Text(
                      'No feedback yet for this term.',
                      style: TextStyle(color: AppColors.mid),
                    ),
                  )
                else
                  for (final feedback in vm.feedbacks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FeedbackListTile(
                        feedback: feedback,
                        onTap: () {
                          context
                              .read<AppNavigationNotifier>()
                              .openCoachFeedbackDetail(feedback.id);
                        },
                        onDelete: () =>
                            _confirmDeleteFeedback(context, vm, feedback),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteFeedback(
    BuildContext context,
    CoachWordHistoryViewModel vm,
    CoachFeedbackEntry feedback,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete feedback?'),
        content: const Text('Remove this coaching feedback entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await vm.deleteFeedback(feedback.id);
    }
  }
}

class _WordHeader extends StatelessWidget {
  const _WordHeader({required this.term});

  final CoachHistoryTermDetail term;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.beigeLight,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term.word,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${term.levelCode.toUpperCase()} · ${term.unitName}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.greenMid,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            term.definition,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mid,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackListTile extends StatelessWidget {
  const _FeedbackListTile({
    required this.feedback,
    required this.onTap,
    required this.onDelete,
  });

  final CoachFeedbackEntry feedback;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CoachHistoryViewModel.formatDateTime(feedback.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.light,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppDecorations.radiusSm),
                        border: const Border(
                          left: BorderSide(color: AppColors.greenMid, width: 3),
                        ),
                      ),
                      child: Text(
                        '"${feedback.userSentence}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.light,
                onPressed: onDelete,
              ),
              const Icon(Icons.chevron_right, color: AppColors.light),
            ],
          ),
        ),
      ),
    );
  }
}
