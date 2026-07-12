import 'dart:convert';

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
import '../../../../shared/vocabulary/domain/entities/unit.dart';
import '../../domain/entities/exam_config.dart';
import '../../domain/entities/exam_history.dart';
import '../../domain/entities/exam_question.dart';
import '../../domain/entities/exam_question_type.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/entities/graded_answer.dart';
import '../viewmodels/exam_view_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Config
// ─────────────────────────────────────────────────────────────────────────────

class ExamConfigPage extends StatefulWidget {
  const ExamConfigPage({
    super.key,
    this.levelCode,
    this.unitName,
    this.unitId,
  });

  final String? levelCode;
  final String? unitName;
  final String? unitId;

  @override
  State<ExamConfigPage> createState() => _ExamConfigPageState();
}

class _ExamConfigPageState extends State<ExamConfigPage> {
  late final ExamConfigViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExamConfigViewModel(
      initialLevelCode: widget.levelCode,
      initialUnitName: widget.unitName,
      initialUnitId: widget.unitId,
    );
    if (widget.unitName != null) {
      _viewModel.allUnits = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initialize();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _startExam() async {
    try {
      await _viewModel.startExam();
      if (!mounted) return;
      context.read<AppNavigationNotifier>().openHomeRoute(
            HomeRoutePaths.examSession,
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: WordunoAppBar(
          title: 'Create Exam',
          titleWidget: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create Exam',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppColors.coralMid,
              ),
            ],
          ),
        ),
        body: Consumer<ExamConfigViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const AppLoading(message: 'Loading configuration...');
            }
            if (vm.errorMessage != null && vm.levels.isEmpty) {
              return AppErrorView(
                message: vm.errorMessage!,
                onRetry: vm.initialize,
              );
            }

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _ExamSectionCard(
                      title: 'Level',
                      child: _ExamDropdownField<String>(
                        value: vm.selectedLevelCode.isEmpty
                            ? null
                            : vm.selectedLevelCode,
                        hint: 'Select level',
                        items: vm.levels
                            .map(
                              (level) => DropdownMenuItem(
                                value: level.code,
                                child: Text(
                                  level.code.toUpperCase().replaceAll('&', ' & '),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) vm.selectLevel(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ExamSectionCard(
                      title: 'Unit',
                      child: Column(
                        children: [
                          _ExamToggleRow(
                            label: 'All units',
                            value: vm.allUnits,
                            onChanged: vm.setAllUnits,
                          ),
                          if (!vm.allUnits) ...[
                            const SizedBox(height: 12),
                            _ExamDropdownField<String>(
                              value: vm.selectedUnitName,
                              hint: 'Select unit',
                              items: vm.units
                                  .map(
                                    (unit) => DropdownMenuItem(
                                      value: unit.name,
                                      child: Text(unit.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                Unit? unit;
                                for (final item in vm.units) {
                                  if (item.name == value) {
                                    unit = item;
                                    break;
                                  }
                                }
                                if (unit != null) vm.selectUnit(unit);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ExamSectionCard(
                      title: 'Options',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ExamToggleRow(
                            label: 'Starred words only',
                            value: vm.starOnly,
                            onChanged: vm.setStarOnly,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          const Text(
                            'Question count',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mid,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ExamConfig.questionCountOptions
                                .map(
                                  (count) => _ExamCountChip(
                                    count: count,
                                    selected: vm.questionCount == count,
                                    onTap: () => vm.setQuestionCount(count),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ExamSectionCard(
                      title: 'Question types',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vm.enabledTypes.length} selected · choose at least one',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mid,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (var i = 0;
                              i < ExamQuestionType.values.length;
                              i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _ExamTypeCheckboxRow(
                              type: ExamQuestionType.values[i],
                              value: vm.enabledTypes
                                  .contains(ExamQuestionType.values[i]),
                              onChanged: (value) {
                                if (value == null) return;
                                vm.toggleQuestionType(
                                  ExamQuestionType.values[i],
                                  value,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      AppErrorBanner(message: vm.errorMessage!),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: vm.canStart ? _startExam : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coralDark,
                          disabledBackgroundColor: AppColors.light,
                          foregroundColor: AppColors.white,
                          disabledForegroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDecorations.radiusLg,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          vm.isStarting ? 'Starting...' : 'Start Exam',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (vm.isStarting)
                  ColoredBox(
                    color: AppColors.ink.withValues(alpha: 0.45),
                    child: const Center(
                      child: AppLoading(message: 'Generating exam...'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session (form-style)
// ─────────────────────────────────────────────────────────────────────────────

class ExamSessionPage extends StatefulWidget {
  const ExamSessionPage({super.key});

  @override
  State<ExamSessionPage> createState() => _ExamSessionPageState();
}

class _ExamSessionPageState extends State<ExamSessionPage> {
  late final ExamSessionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExamSessionViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await _viewModel.submit();
      if (!mounted) return;
      context.read<AppNavigationNotifier>().openHomeRoute(
            HomeRoutePaths.examResult,
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: const WordunoAppBar(title: 'Exam'),
        body: Consumer<ExamSessionViewModel>(
          builder: (context, vm, _) {
            final paper = vm.paper;
            if (paper == null) {
              return const AppErrorView(
                message: 'No exam loaded. Go back and create a new exam.',
              );
            }

            return Column(
              children: [
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppErrorBanner(message: vm.errorMessage!),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: paper.questions.length,
                    itemBuilder: (context, index) {
                      final question = paper.questions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _QuestionCard(
                          index: index + 1,
                          question: question,
                          answer: vm.answers[question.id],
                          onChanged: (value) => vm.setAnswer(question.id, value),
                          onMatchingChanged: (pairs) =>
                              vm.setMatchingAnswer(question.id, pairs),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: Consumer<ExamSessionViewModel>(
          builder: (context, vm, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: vm.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coralDark,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDecorations.radiusSm),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      vm.isSubmitting ? 'Submitting...' : 'Submit Exam',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.answer,
    required this.onChanged,
    required this.onMatchingChanged,
  });

  final int index;
  final ExamQuestion question;
  final String? answer;
  final ValueChanged<String> onChanged;
  final ValueChanged<Map<String, String>> onMatchingChanged;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.answer ?? '';
  }

  @override
  void didUpdateWidget(covariant _QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer && widget.answer != _textController.text) {
      _textController.text = widget.answer ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.beigeLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.index}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.coralDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.question.type.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.question.displayStem,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    final question = widget.question;

    if (question.type == ExamQuestionType.matching &&
        question.matchingPairs != null &&
        question.shuffledDefinitions != null) {
      return _MatchingInput(
        pairs: question.matchingPairs!,
        definitions: question.shuffledDefinitions!,
        initialAnswer: widget.answer,
        onChanged: widget.onMatchingChanged,
      );
    }

    if (question.options != null) {
      return Column(
        children: question.options!.map((option) {
          return RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: Text(option),
            value: option,
            groupValue: widget.answer,
            activeColor: AppColors.coralDark,
            onChanged: (value) {
              if (value != null) widget.onChanged(value);
            },
          );
        }).toList(),
      );
    }

    return TextField(
      controller: _textController,
      maxLines: question.type == ExamQuestionType.sentenceWritingAi ? 4 : 1,
      decoration: _inputDecoration('Your answer'),
      onChanged: widget.onChanged,
    );
  }
}

class _MatchingInput extends StatefulWidget {
  const _MatchingInput({
    required this.pairs,
    required this.definitions,
    required this.onChanged,
    this.initialAnswer,
  });

  final List<MatchingPair> pairs;
  final List<String> definitions;
  final ValueChanged<Map<String, String>> onChanged;
  final String? initialAnswer;

  @override
  State<_MatchingInput> createState() => _MatchingInputState();
}

class _MatchingInputState extends State<_MatchingInput> {
  late Map<String, String> _selections;

  @override
  void initState() {
    super.initState();
    _selections = {};
    if (widget.initialAnswer != null && widget.initialAnswer!.isNotEmpty) {
      try {
        final decoded =
            jsonDecode(widget.initialAnswer!) as Map<String, dynamic>;
        _selections = decoded.map((k, v) => MapEntry(k, v as String));
      } catch (_) {}
    }
  }

  void _update(String termId, String? definition) {
    setState(() {
      if (definition == null) {
        _selections.remove(termId);
      } else {
        _selections[termId] = definition;
      }
    });
    widget.onChanged(_selections);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.pairs.map((pair) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  pair.termText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selections[pair.termId],
                  decoration: _inputDecoration('Definition'),
                  items: widget.definitions
                      .map(
                        (definition) => DropdownMenuItem(
                          value: definition,
                          child: Text(
                            definition,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) {
                    return widget.definitions
                        .map(
                          (definition) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              definition,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList();
                  },
                  onChanged: (value) => _update(pair.termId, value),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result
// ─────────────────────────────────────────────────────────────────────────────

class ExamResultPage extends StatefulWidget {
  const ExamResultPage({super.key});

  @override
  State<ExamResultPage> createState() => _ExamResultPageState();
}

class _ExamResultPageState extends State<ExamResultPage> {
  late final ExamResultViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExamResultViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: const WordunoAppBar(title: 'Exam Result', showBack: false),
        body: Consumer<ExamResultViewModel>(
          builder: (context, vm, _) {
            final result = vm.result;
            if (result == null) {
              return const AppErrorView(message: 'No result available.');
            }

            if (vm.reviewMode) {
              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: vm.toggleReview,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to summary'),
                    ),
                  ),
                  Expanded(child: _ReviewList(result: result)),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ScoreCard(result: result),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: vm.toggleReview,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.coralDark,
                      side: const BorderSide(color: AppColors.coralDark),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDecorations.radiusSm),
                      ),
                    ),
                    child: const Text(
                      'Review Answers',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<AppNavigationNotifier>()
                          .resetHomeToRoot();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coralDark,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDecorations.radiusSm),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return _SimpleScoreCard(
      percentage: result.percentage,
      subtitle:
          '${result.correctCount} correct • ${result.wrongCount} wrong',
    );
  }
}

class _SimpleScoreCard extends StatelessWidget {
  const _SimpleScoreCard({
    required this.percentage,
    required this.subtitle,
  });

  final double percentage;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.examScore(percentage / 100);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            '${percentage.round()}%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: palette.fg,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: palette.fg.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        for (var i = 0; i < result.answers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReviewCard(index: i + 1, answer: result.answers[i]),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.index, required this.answer});

  final int index;
  final GradedAnswer answer;

  @override
  Widget build(BuildContext context) {
    final color = answer.isCorrect ? AppColors.greenDark : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Q$index',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Icon(
                answer.isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(answer.question.displayStem),
          const SizedBox(height: 8),
          Text('Your answer: ${answer.userAnswer}'),
          if (answer.feedback != null) ...[
            const SizedBox(height: 8),
            Text(answer.feedback!),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              answer.isCorrect ? 'Correct' : 'Expected: ${answer.question.correctAnswer ?? answer.question.definition}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History
// ─────────────────────────────────────────────────────────────────────────────

class ExamHistoryPage extends StatefulWidget {
  const ExamHistoryPage({super.key});

  @override
  State<ExamHistoryPage> createState() => _ExamHistoryPageState();
}

class _ExamHistoryPageState extends State<ExamHistoryPage> {
  late final ExamHistoryViewModel _viewModel;
  String? _lastExamDetailId;

  @override
  void initState() {
    super.initState();
    _viewModel = ExamHistoryViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.load();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final examDetailId =
        context.watch<AppNavigationNotifier>().configuration.examDetailId;
    if (_lastExamDetailId != null && examDetailId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _viewModel.load();
      });
    }
    _lastExamDetailId = examDetailId;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: const WordunoAppBar(title: 'Exam History'),
        body: Consumer<ExamHistoryViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const AppLoading(message: 'Loading history...');
            }
            if (vm.errorMessage != null) {
              return AppErrorView(message: vm.errorMessage!, onRetry: vm.load);
            }
            if (vm.items.isEmpty) {
              return const Center(child: Text('No exams yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: vm.items.length,
              itemBuilder: (context, index) {
                final item = vm.items[index];
                return _HistoryTile(item: item);
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final ExamHistorySummary item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          item.unitLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_formatDate(item.date)} • ${item.questionCount} questions',
        ),
        trailing: Text(
          '${item.score.round()}%',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.examScore(item.score / 100).fg,
          ),
        ),
        onTap: () => context
            .read<AppNavigationNotifier>()
            .openExamDetail(item.id),
      ),
    );
  }
}

class ExamDetailPage extends StatefulWidget {
  const ExamDetailPage({super.key, required this.examId});

  final String examId;

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  late final ExamDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExamDetailViewModel(examId: widget.examId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.load();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete exam?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _viewModel.deleteExam();
    if (!mounted) return;
    context.read<AppNavigationNotifier>().popExamDetail();
    _viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: WordunoAppBar(
          title: 'Exam Detail',
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _delete,
            ),
          ],
        ),
        body: Consumer<ExamDetailViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const AppLoading(message: 'Loading exam...');
            }
            if (vm.errorMessage != null) {
              return AppErrorView(message: vm.errorMessage!, onRetry: vm.load);
            }
            final detail = vm.detail;
            if (detail == null) {
              return const AppErrorView(message: 'Exam not found.');
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SimpleScoreCard(
                  percentage: detail.score,
                  subtitle:
                      '${_formatDate(detail.date)} • ${detail.questionCount} questions',
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < detail.questions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryQuestionCard(
                      index: i + 1,
                      item: detail.questions[i],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryQuestionCard extends StatelessWidget {
  const _HistoryQuestionCard({required this.index, required this.item});

  final int index;
  final ExamHistoryQuestion item;

  @override
  Widget build(BuildContext context) {
    final color = item.isCorrect ? AppColors.greenDark : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q$index • ${item.type.label}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(item.question),
          const SizedBox(height: 8),
          Text('Your answer: ${item.userAnswer}'),
          const SizedBox(height: 4),
          Text(
            item.isCorrect ? 'Correct' : 'Correct: ${item.correctAnswer}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ExamSectionCard extends StatelessWidget {
  const _ExamSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ExamDropdownField<T> extends StatelessWidget {
  const _ExamDropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: _examInputDecoration(hint),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.mid,
        size: 22,
      ),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _ExamToggleRow extends StatelessWidget {
  const _ExamToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ExamCountChip extends StatelessWidget {
  const _ExamCountChip({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.beigeLight : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        side: BorderSide(
          color: selected ? AppColors.coral : AppColors.border,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.coralDark,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.coralDark : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamTypeCheckboxRow extends StatelessWidget {
  const _ExamTypeCheckboxRow({
    required this.type,
    required this.value,
    required this.onChanged,
  });

  final ExamQuestionType type;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value
          ? AppColors.withAlpha27(AppColors.green)
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        side: BorderSide(
          color: value
              ? AppColors.greenMid.withValues(alpha: 0.4)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            type.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (type.isAiPowered) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.withAlpha27(
                                AppColors.beigeLight,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDecorations.radiusPill,
                              ),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.coralDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.description,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mid,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.greenDark,
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _examInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: AppColors.light,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      borderSide: const BorderSide(color: AppColors.border, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      borderSide: const BorderSide(color: AppColors.greenMid, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      borderSide: const BorderSide(color: AppColors.greenMid, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

String _formatDate(DateTime date) {
  final today = DateTime.now();
  final currentDate = DateTime(today.year, today.month, today.day);
  final targetDate = DateTime(date.year, date.month, date.day);
  final daysAgo = currentDate.difference(targetDate).inDays;

  if (daysAgo == 0) {
    return 'Today';
  }
  if (daysAgo == 1) {
    return 'Yesterday';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
