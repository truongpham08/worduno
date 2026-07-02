import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../viewmodels/coach_history_view_model.dart';

class CoachFeedbackDetailPage extends StatefulWidget {
  const CoachFeedbackDetailPage({super.key, required this.feedbackId});

  final String feedbackId;

  @override
  State<CoachFeedbackDetailPage> createState() =>
      _CoachFeedbackDetailPageState();
}

class _CoachFeedbackDetailPageState extends State<CoachFeedbackDetailPage> {
  late final CoachFeedbackDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CoachFeedbackDetailViewModel(feedbackId: widget.feedbackId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.load());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _delete(BuildContext context) async {
    final feedback = _viewModel.feedback;
    if (feedback == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete feedback?'),
        content: Text('Remove feedback for "${feedback.word}"?'),
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
      await _viewModel.deleteFeedback();
      if (context.mounted) {
        context.read<AppNavigationNotifier>().popCoachRoute();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoachFeedbackDetailViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2FA),
        appBar: WordunoAppBar(
          title: 'Feedback Detail',
          actions: [
            Consumer<CoachFeedbackDetailViewModel>(
              builder: (context, vm, _) {
                if (vm.feedback == null) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context),
                );
              },
            ),
          ],
        ),
        body: Consumer<CoachFeedbackDetailViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const AppLoading(message: 'Loading feedback...');
            }
            if (vm.errorMessage != null) {
              return AppErrorView(message: vm.errorMessage!, onRetry: vm.load);
            }

            final feedback = vm.feedback;
            final result = feedback?.evaluateResult;
            if (feedback == null || result == null) {
              return const AppErrorView(message: 'Feedback not available.');
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  feedback.word,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CoachHistoryViewModel.formatDateTime(feedback.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF8B5CF6), width: 4),
                    ),
                  ),
                  child: Text(
                    '"${feedback.userSentence}"',
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF374151),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _DetailCard(
                  title: 'Grammar',
                  content: result.grammar,
                  color: const Color(0xFFDBEAFE),
                  iconColor: const Color(0xFF2563EB),
                  icon: Icons.menu_book_outlined,
                ),
                const SizedBox(height: 10),
                _DetailCard(
                  title: 'Vocabulary',
                  content: result.vocabulary,
                  color: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF059669),
                  icon: Icons.edit_outlined,
                ),
                const SizedBox(height: 10),
                _DetailCard(
                  title: 'Naturalness',
                  content: result.naturalness,
                  color: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  icon: Icons.chat_bubble_outline,
                ),
                if (result.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _DetailCard(
                    title: 'Suggestion',
                    content: result.suggestions.map((s) => '• $s').join('\n'),
                    color: const Color(0xFFFCE7F3),
                    iconColor: const Color(0xFFDB2777),
                    icon: Icons.lightbulb_outline,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.content,
    required this.color,
    required this.iconColor,
    required this.icon,
  });

  final String title;
  final String content;
  final Color color;
  final Color iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                    height: 1.45,
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
