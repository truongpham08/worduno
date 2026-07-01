import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/navigation/app_navigation_notifier.dart';
import '../../../../app/routes/route_paths.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
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
        backgroundColor: const Color(0xFFF0F2FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF111827)),
          title: const Text(
            'Create Exam',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    _SectionCard(
                      title: 'Level',
                      child: DropdownButtonFormField<String>(
                        value: vm.selectedLevelCode.isEmpty
                            ? null
                            : vm.selectedLevelCode,
                        decoration: _inputDecoration('Select level'),
                        items: vm.levels
                            .map(
                              (level) => DropdownMenuItem(
                                value: level.code,
                                child: Text(level.code.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) vm.selectLevel(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Unit',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('All units'),
                            value: vm.allUnits,
                            activeThumbColor: const Color(0xFF3B82F6),
                            onChanged: vm.setAllUnits,
                          ),
                          if (!vm.allUnits)
                            DropdownButtonFormField<String>(
                              value: vm.selectedUnitName,
                              decoration: _inputDecoration('Select unit'),
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Options',
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Starred words only'),
                            value: vm.starOnly,
                            activeThumbColor: const Color(0xFF3B82F6),
                            onChanged: vm.setStarOnly,
                          ),
                          const Divider(height: 24),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Question count',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ExamConfig.questionCountOptions
                                .map(
                                  (count) => ChoiceChip(
                                    label: Text('$count'),
                                    selected: vm.questionCount == count,
                                    selectedColor:
                                        const Color(0xFFDBEAFE),
                                    onSelected: (_) =>
                                        vm.setQuestionCount(count),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Question types',
                      child: Column(
                        children: ExamQuestionType.values
                            .map(
                              (type) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(type.label),
                                value: vm.enabledTypes.contains(type),
                                activeColor: const Color(0xFF3B82F6),
                                onChanged: (value) {
                                  if (value == null) return;
                                  vm.toggleQuestionType(type, value);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ],
                  ],
                ),
                if (vm.isStarting)
                  const ColoredBox(
                    color: Color(0x88000000),
                    child: Center(
                      child: AppLoading(message: 'Generating exam...'),
                    ),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: Consumer<ExamConfigViewModel>(
          builder: (context, vm, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: vm.canStart ? _startExam : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      vm.isStarting ? 'Starting...' : 'Start Exam',
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
        backgroundColor: const Color(0xFFF0F2FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF111827)),
          title: const Text(
            'Exam',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
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
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.index}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.question.type.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
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
              color: Color(0xFF111827),
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
            activeColor: const Color(0xFF3B82F6),
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
        backgroundColor: const Color(0xFFF0F2FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Exam Result',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '${percentage.round()}%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
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
    final color =
        answer.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Exam History',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF3B82F6),
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
        backgroundColor: const Color(0xFFF0F2FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Exam Detail',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
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
    final color =
        item.isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
