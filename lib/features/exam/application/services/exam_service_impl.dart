import '../../domain/entities/exam_config.dart';
import '../../domain/entities/exam_history.dart';
import '../../domain/entities/exam_paper.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/entities/graded_answer.dart';
import '../../domain/entities/exam_source_term.dart';
import '../../domain/repositories/i_exam_repository.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';
import 'exam_grader.dart';
import 'exam_question_generator.dart';
import 'i_exam_service.dart';

class ExamServiceImpl implements IExamService {
  ExamServiceImpl(
    this._vocabularyService,
    this._wordStateStore,
    this._repository,
    this._questionGenerator,
    this._grader,
  );

  final IVocabularyService _vocabularyService;
  final WordStateStore _wordStateStore;
  final IExamRepository _repository;
  final ExamQuestionGenerator _questionGenerator;
  final ExamGrader _grader;

  ExamPaper? _currentPaper;
  ExamResult? _currentResult;
  bool _isGenerating = false;

  @override
  ExamPaper? get currentPaper => _currentPaper;

  @override
  ExamResult? get currentResult => _currentResult;

  @override
  bool get isGenerating => _isGenerating;

  @override
  Future<ExamPaper> prepareExam(ExamConfig config) async {
    _isGenerating = true;
    _currentResult = null;

    try {
      final pool = await _loadTermPool(config);
      final paper = await _questionGenerator.generate(
        config: config,
        pool: pool,
      );
      _currentPaper = paper;
      return paper;
    } finally {
      _isGenerating = false;
    }
  }

  @override
  Future<ExamResult> submitExam(Map<String, String?> answersByQuestionId) async {
    final paper = _currentPaper;
    if (paper == null) {
      throw StateError('No active exam paper.');
    }

    final graded = <GradedAnswer>[];
    for (final question in paper.questions) {
      final raw = answersByQuestionId[question.id];
      graded.add(await _grader.grade(question: question, rawAnswer: raw));
    }

    final correctCount = graded.where((answer) => answer.isCorrect).length;
    final wrongCount = graded.length - correctCount;
    final percentage = graded.isEmpty
        ? 0.0
        : (correctCount / graded.length) * 100.0;

    final result = ExamResult(
      examId: paper.id,
      paper: paper,
      answers: graded,
      correctCount: correctCount,
      wrongCount: wrongCount,
      percentage: percentage,
      completedAt: DateTime.now(),
    );

    await _repository.saveExamResult(result);
    _currentResult = result;
    return result;
  }

  @override
  void clearSession() {
    _currentPaper = null;
    _currentResult = null;
  }

  @override
  Future<List<ExamHistorySummary>> getHistory() {
    return _repository.getExamHistory();
  }

  @override
  Future<ExamHistoryDetail?> getHistoryDetail(String examId) {
    return _repository.getExamDetail(examId);
  }

  @override
  Future<void> deleteHistory(String examId) {
    return _repository.deleteExam(examId);
  }

  Future<List<ExamSourceTerm>> _loadTermPool(ExamConfig config) async {
    final terms = <ExamSourceTerm>[];

    if (config.unitName != null && config.unitName!.isNotEmpty) {
      final unitTerms = await _vocabularyService.getTerms(
        levelCode: config.levelCode,
        unitName: config.unitName!,
      );
      await _wordStateStore.ensureLoaded(config.unitId, forceReload: true);
      for (final term in unitTerms) {
        if (_includeTerm(config, config.unitId, term.id)) {
          terms.add(
            ExamSourceTerm(
              unitId: config.unitId,
              unitName: config.unitName!,
              termId: term.id,
              text: term.text,
              definition: term.definition,
            ),
          );
        }
      }
      return terms;
    }

    final units = await _vocabularyService.getUnits(config.levelCode);
    for (final unit in units) {
      final unitTerms = await _vocabularyService.getTerms(
        levelCode: config.levelCode,
        unitName: unit.name,
      );
      await _wordStateStore.ensureLoaded(unit.id, forceReload: true);
      for (final term in unitTerms) {
        if (_includeTerm(config, unit.id, term.id)) {
          terms.add(
            ExamSourceTerm(
              unitId: unit.id,
              unitName: unit.name,
              termId: term.id,
              text: term.text,
              definition: term.definition,
            ),
          );
        }
      }
    }
    return terms;
  }

  bool _includeTerm(ExamConfig config, String unitId, String termId) {
    if (!config.starOnly) {
      return true;
    }
    final state = _wordStateStore.stateFor(unitId: unitId, termId: termId);
    return state.isStarred;
  }
}
