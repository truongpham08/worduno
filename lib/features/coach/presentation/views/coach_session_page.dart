import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/tts_helper.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_navigation_widgets.dart';
import '../../domain/entities/coach_entities.dart';
import '../viewmodels/coach_session_view_model.dart';

class CoachSessionPage extends StatefulWidget {
  const CoachSessionPage({super.key});

  @override
  State<CoachSessionPage> createState() => _CoachSessionPageState();
}

class _CoachSessionPageState extends State<CoachSessionPage> {
  late final CoachSessionViewModel _viewModel;
  final _sentenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = CoachSessionViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initSession();
    });
    _viewModel.addListener(_syncSentenceField);
  }

  void _syncSentenceField() {
    if (_sentenceController.text != _viewModel.userSentence) {
      _sentenceController.text = _viewModel.userSentence;
      _sentenceController.selection = TextSelection.collapsed(
        offset: _viewModel.userSentence.length,
      );
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_syncSentenceField);
    _viewModel.endSession();
    _viewModel.dispose();
    _sentenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoachSessionViewModel>.value(
      value: _viewModel,
      child: Consumer<CoachSessionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: const WordunoAppBar(title: 'AI Coach'),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(child: _buildBody(context, vm)),
                  if (_showActionBar(vm)) _SessionActionBar(vm: vm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _showActionBar(CoachSessionViewModel vm) {
    return switch (vm.phase) {
      CoachSessionPhase.explainLoading ||
      CoachSessionPhase.explain ||
      CoachSessionPhase.explainError ||
      CoachSessionPhase.writing ||
      CoachSessionPhase.evaluating ||
      CoachSessionPhase.feedback =>
        vm.currentWord != null,
      _ => false,
    };
  }

  Widget _buildBody(BuildContext context, CoachSessionViewModel vm) {
    return switch (vm.phase) {
      CoachSessionPhase.loading => const AppLoading(
          message: 'Preparing coach session...',
        ),
      CoachSessionPhase.completed => _CompletionView(
          feedbackCount: vm.feedbackCount,
          skippedCount: vm.skippedCount,
          totalWords: vm.totalWords,
          onDone: () {
            context
                .read<AppNavigationNotifier>()
                .completeCoachSessionAndOpenHistory();
          },
        ),
      CoachSessionPhase.explainLoading ||
      CoachSessionPhase.explain ||
      CoachSessionPhase.explainError ||
      CoachSessionPhase.writing ||
      CoachSessionPhase.evaluating ||
      CoachSessionPhase.feedback =>
        vm.currentWord == null
            ? AppErrorView(
                message: vm.errorMessage ?? 'Session error.',
                onRetry: vm.initSession,
              )
            : _SessionContent(
                vm: vm,
                sentenceController: _sentenceController,
              ),
    };
  }
}

class _SessionContent extends StatelessWidget {
  const _SessionContent({
    required this.vm,
    required this.sentenceController,
  });

  final CoachSessionViewModel vm;
  final TextEditingController sentenceController;

  @override
  Widget build(BuildContext context) {
    final word = vm.currentWord!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _ProgressHeader(
          current: vm.currentIndex + 1,
          total: vm.totalWords,
        ),
        const SizedBox(height: 16),
        if (vm.phase == CoachSessionPhase.explainLoading)
          const AppLoading(message: 'Loading explanation...')
        else if (vm.phase == CoachSessionPhase.explainError)
          _ExplainErrorCard(
            message: vm.errorMessage ?? 'Failed to load explanation.',
            onRetry: vm.retryExplain,
            onSkip: vm.skipExplain,
          )
        else if (vm.phase == CoachSessionPhase.explain &&
            vm.explainResult != null)
          _ExplainCard(
            word: word,
            result: vm.explainResult!,
            onUnderstand: vm.acknowledgeExplain,
          )
        else if (vm.phase == CoachSessionPhase.writing ||
            vm.phase == CoachSessionPhase.evaluating) ...[
          if (vm.skippedExplain) const SizedBox.shrink(),
          _WordCard(
            word: word,
            showDefinition: true,
          ),
          const SizedBox(height: 20),
          _WritingSection(
            word: word,
            controller: sentenceController,
            isEvaluating: vm.phase == CoachSessionPhase.evaluating,
            errorMessage: vm.errorMessage,
            onChanged: vm.updateSentence,
            onSubmit: vm.submitSentence,
          ),
        ] else if (vm.phase == CoachSessionPhase.feedback &&
            vm.evaluateResult != null) ...[
          _WordCard(
            word: word,
            showDefinition: true,
            userSentence: vm.userSentence,
          ),
          const SizedBox(height: 20),
          _FeedbackSection(result: vm.evaluateResult!),
        ],
      ],
    );
  }
}

class _SessionActionBar extends StatelessWidget {
  const _SessionActionBar({required this.vm});

  final CoachSessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final isFeedback = vm.phase == CoachSessionPhase.feedback;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: vm.canGoBack ? vm.goToPreviousWord : null,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isFeedback ? vm.nextWord : vm.skipCurrentWord,
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: Text(isFeedback ? 'Next' : 'Skip'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: vm.finishSessionEarly,
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text('End'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mid,
                foregroundColor: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Word $current of $total',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mid,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.greenMid,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: AppColors.greenMid,
          ),
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.showDefinition,
    this.userSentence,
  });

  final CoachWord word;
  final bool showDefinition;
  final String? userSentence;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.beigeLight,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        boxShadow: AppDecorations.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  word.term.text,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _ListenButton(onTap: () => TtsHelper.speak(word.term.text)),
            ],
          ),
          if (showDefinition) ...[
            const SizedBox(height: 8),
            Text(
              word.term.definition,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.mid,
                height: 1.4,
              ),
            ),
          ],
          if (userSentence != null && userSentence!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
              ),
              child: Text(
                '"$userSentence"',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.volume_up_rounded, size: 18),
      label: const Text('Listen'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.greenMid,
        backgroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
        ),
      ),
    );
  }
}

class _ExplainCard extends StatelessWidget {
  const _ExplainCard({
    required this.word,
    required this.result,
    required this.onUnderstand,
  });

  final CoachWord word;
  final CoachExplainResult result;
  final VoidCallback onUnderstand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WordCard(word: word, showDefinition: true),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: AppDecorations.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.greenMid),
                  SizedBox(width: 8),
                  Text(
                    'How to use this word',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                result.usage,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mid,
                  height: 1.5,
                ),
              ),
              if (result.contexts.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Contexts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mid,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.contexts
                      .map(
                        (c) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppDecorations.radiusPill,
                            ),
                          ),
                          child: Text(
                            c,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (result.examples.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Examples',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mid,
                  ),
                ),
                const SizedBox(height: 8),
                for (final example in result.examples)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.beigeLight,
                        borderRadius: BorderRadius.circular(
                          AppDecorations.radiusSm,
                        ),
                        border: Border.all(color: AppColors.green),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            example.sentence,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          if (example.note.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              example.note,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mid,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: onUnderstand,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.greenDark,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
              ),
            ),
            child: const Text(
              'I understand',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExplainErrorCard extends StatelessWidget {
  const _ExplainErrorCard({
    required this.message,
    required this.onRetry,
    required this.onSkip,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(),
      child: Column(
        children: [
          AppErrorBanner(message: message),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.greenDark,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _writingFieldBorder({bool focused = false}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(
      color: focused ? AppColors.greenMid : AppColors.border,
      width: 1.5,
    ),
  );
}

class _WritingSection extends StatelessWidget {
  const _WritingSection({
    required this.word,
    required this.controller,
    required this.isEvaluating,
    required this.errorMessage,
    required this.onChanged,
    required this.onSubmit,
  });

  final CoachWord word;
  final TextEditingController controller;
  final bool isEvaluating;
  final String? errorMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Write a sentence using '${word.term.text}'",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          enabled: !isEvaluating,
          maxLines: 4,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Type your sentence here...',
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.all(14),
            border: _writingFieldBorder(),
            enabledBorder: _writingFieldBorder(),
            focusedBorder: _writingFieldBorder(focused: true),
            disabledBorder: _writingFieldBorder(),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          AppErrorBanner(message: errorMessage!),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: isEvaluating ? null : onSubmit,
            icon: isEvaluating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              isEvaluating ? 'Getting feedback...' : 'Get AI Feedback',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.greenMid,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({required this.result});

  final CoachEvaluateResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FeedbackCard(
          title: 'Grammar',
          content: result.grammar,
          color: AppColors.blue,
          icon: Icons.menu_book_outlined,
          iconColor: AppColors.greenDark,
        ),
        const SizedBox(height: 10),
        _FeedbackCard(
          title: 'Vocabulary',
          content: result.vocabulary,
          color: AppColors.green,
          icon: Icons.edit_outlined,
          iconColor: AppColors.greenDark,
        ),
        const SizedBox(height: 10),
        _FeedbackCard(
          title: 'Naturalness',
          content: result.naturalness,
          color: AppColors.beigeLight,
          icon: Icons.chat_bubble_outline,
          iconColor: AppColors.coralMid,
        ),
        if (result.suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          _FeedbackCard(
            title: 'Suggestion',
            content: result.suggestions.map((s) => '• $s').join('\n'),
            color: AppColors.beige,
            icon: Icons.lightbulb_outline,
            iconColor: AppColors.coralDark,
          ),
        ],
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.title,
    required this.content,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String content;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
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
                    color: AppColors.ink,
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

class _CompletionView extends StatefulWidget {
  const _CompletionView({
    required this.feedbackCount,
    required this.skippedCount,
    required this.totalWords,
    required this.onDone,
  });

  final int feedbackCount;
  final int skippedCount;
  final int totalWords;
  final VoidCallback onDone;

  @override
  State<_CompletionView> createState() => _CompletionViewState();
}

class _CompletionViewState extends State<_CompletionView> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.skippedCount > 0
        ? '${widget.feedbackCount} words with feedback · ${widget.skippedCount} skipped'
        : '${widget.feedbackCount} words with feedback';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.beigeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                size: 44,
                color: AppColors.greenMid,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You completed your AI Coach session.\n$summary',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.mid,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: widget.onDone,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text(
                'Go to History',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
