import 'package:worduno/features/coach/application/services/i_coach_service.dart';
import 'package:worduno/features/coach/data/datasources/i_coach_ai_data_source.dart';
import 'package:worduno/features/coach/data/datasources/i_coach_history_local_data_source.dart';
import 'package:worduno/features/coach/domain/entities/coach_entities.dart';
import 'package:worduno/features/coach/domain/entities/coach_star_filter.dart';
import 'package:worduno/features/dashboard/application/models/dashboard_data.dart';
import 'package:worduno/features/dashboard/application/services/i_dashboard_service.dart';
import 'package:worduno/features/exam/application/services/i_exam_service.dart';
import 'package:worduno/features/exam/data/datasources/i_exam_ai_data_source.dart';
import 'package:worduno/features/exam/data/dtos/exam_ai_dtos.dart';
import 'package:worduno/features/exam/domain/entities/exam_config.dart';
import 'package:worduno/features/exam/domain/entities/exam_history.dart';
import 'package:worduno/features/exam/domain/entities/exam_paper.dart';
import 'package:worduno/features/exam/domain/entities/exam_question.dart';
import 'package:worduno/features/exam/domain/entities/exam_question_type.dart';
import 'package:worduno/features/exam/domain/entities/exam_result.dart';
import 'package:worduno/features/exam/domain/entities/graded_answer.dart';
import 'package:worduno/features/learning/application/services/i_learn_service.dart';
import 'package:worduno/features/learning/domain/entities/learn_session_data.dart';
import 'package:worduno/shared/vocabulary/application/services/i_vocabulary_service.dart';
import 'package:worduno/shared/vocabulary/domain/entities/level.dart';
import 'package:worduno/shared/vocabulary/domain/entities/term.dart';
import 'package:worduno/shared/vocabulary/domain/entities/unit.dart';
import 'package:worduno/shared/word_state/domain/entities/user_word_state.dart';
import 'package:worduno/shared/word_state/domain/entities/word_status.dart';
import 'package:worduno/shared/word_state/domain/repositories/i_word_state_repository.dart';

List<Term> sampleTerms({int count = 10, String prefix = 'term'}) => [
      for (var i = 0; i < count; i++)
        Term(
          id: '$prefix$i',
          text: '$prefix$i',
          definition: 'def$i',
        ),
    ];

List<ExamSourceTermLike> sampleExamPool({int count = 15}) => [
      for (var i = 0; i < count; i++)
        ExamSourceTermLike(
          unitId: 'b1-0',
          unitName: 'Travel',
          termId: 't$i',
          text: 'word$i',
          definition: 'meaning$i',
        ),
    ];

class ExamSourceTermLike {
  const ExamSourceTermLike({
    required this.unitId,
    required this.unitName,
    required this.termId,
    required this.text,
    required this.definition,
  });

  final String unitId;
  final String unitName;
  final String termId;
  final String text;
  final String definition;
}

class FakeVocabularyService implements IVocabularyService {
  FakeVocabularyService({
    this.levels = const [
      Level(code: 'b1', totalTerms: 10, knownTerms: 0),
      Level(code: 'b2', totalTerms: 8, knownTerms: 0),
      Level(code: 'c1&c2', totalTerms: 6, knownTerms: 0),
    ],
    this.unitsByLevel = const {
      'b1': [Unit(id: 'b1-0', name: 'Travel', totalTerms: 10, knownTerms: 0)],
      'b2': [Unit(id: 'b2-0', name: 'Work', totalTerms: 8, knownTerms: 0)],
    },
    this.termsByUnit = const {},
    this.throwOnGetTerms = false,
  });

  final List<Level> levels;
  final Map<String, List<Unit>> unitsByLevel;
  final Map<String, List<Term>> termsByUnit;
  final bool throwOnGetTerms;

  int getTermsCalls = 0;

  @override
  Future<List<Level>> getLevels() async => levels;

  @override
  Future<List<Unit>> getUnits(String levelCode) async =>
      unitsByLevel[levelCode] ?? const [];

  @override
  Future<List<Term>> getTerms({
    required String levelCode,
    required String unitName,
  }) async {
    getTermsCalls++;
    if (throwOnGetTerms) {
      throw Exception('Network error');
    }
    final key = '$levelCode|$unitName';
    return termsByUnit[key] ?? sampleTerms(count: 12);
  }

  @override
  Future<void> clearCache() async {}
}

class StubExamAiDataSource implements IExamAiDataSource {
  StubExamAiDataSource({
    this.throwOnCloze = false,
    this.throwOnEvaluate = false,
    this.evaluateScore = 8,
  });

  final bool throwOnCloze;
  final bool throwOnEvaluate;
  final int evaluateScore;

  @override
  Future<ClozeResponseDto> generateCloze({
    required String word,
    required String definition,
    required String level,
  }) async {
    if (throwOnCloze) {
      throw Exception('AI cloze unavailable');
    }
    return ClozeResponseDto(
      sentence: 'She felt _____ today.',
      options: [word, 'sad', 'angry', 'tired'],
      correctAnswer: word,
    );
  }

  @override
  Future<EvaluateSentenceResponseDto> evaluateSentenceWriting({
    required String word,
    required String definition,
    required String sentence,
  }) async {
    if (throwOnEvaluate) {
      throw Exception('AI evaluate unavailable');
    }
    return EvaluateSentenceResponseDto(
      score: evaluateScore,
      grammar: 'Good',
      vocabulary: 'Good',
      naturalness: 'Good',
      suggestions: const ['Nice'],
    );
  }
}

class StubCoachAiDataSource implements ICoachAiDataSource {
  @override
  Future<Map<String, dynamic>> explainWord({
    required String word,
    required String definition,
  }) async {
    return {
      'usage': 'Common verb',
      'contexts': ['daily life'],
      'examples': [
        {'sentence': 'I use $word every day.', 'note': 'Basic usage'},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> evaluateSentence({
    required String word,
    required String sentence,
  }) async {
    return {
      'grammar': 'Correct',
      'vocabulary': 'Appropriate',
      'naturalness': 'Natural',
      'suggestion': ['Well done'],
    };
  }
}

class FakeCoachHistoryLocalDataSource implements ICoachHistoryLocalDataSource {
  final List<CoachFeedbackEntry> _entries = [];

  @override
  Future<void> insertFeedback(CoachFeedbackEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<CoachHistoryTerm>> getCoachedTerms() async => [];

  @override
  Future<CoachHistoryTerm?> getCoachedTerm({
    required String unitId,
    required String termId,
  }) async =>
      null;

  @override
  Future<List<CoachFeedbackEntry>> getFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) async =>
      _entries
          .where((e) => e.unitId == unitId && e.termId == termId)
          .toList();

  @override
  Future<CoachFeedbackEntry?> getFeedbackById(String feedbackId) async =>
      _entries.cast<CoachFeedbackEntry?>().firstWhere(
            (e) => e?.id == feedbackId,
            orElse: () => null,
          );

  @override
  Future<void> deleteFeedback(String feedbackId) async {
    _entries.removeWhere((e) => e.id == feedbackId);
  }

  @override
  Future<void> deleteAllFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) async {
    _entries.removeWhere(
      (e) => e.unitId == unitId && e.termId == termId,
    );
  }
}

class FakeLearnService implements ILearnService {
  FakeLearnService(this._data);

  final LearnSessionData _data;
  final List<(String termId, WordStatus status)> statusUpdates = [];
  final List<String> starToggles = [];

  @override
  Future<LearnSessionData> loadSessionData({
    required String levelCode,
    required String unitName,
    String? unitId,
  }) async =>
      _data;

  @override
  Future<void> markStatus({
    required String unitId,
    required String termId,
    required WordStatus status,
  }) async {
    statusUpdates.add((termId, status));
  }

  @override
  Future<void> toggleStar({
    required String unitId,
    required String termId,
  }) async {
    starToggles.add(termId);
  }
}

class FakeDashboardService implements IDashboardService {
  @override
  Future<DashboardData> getDashboardData() async {
    return const DashboardData(
      overallProgress: 0.5,
      totalTerms: 4,
      knownTerms: 2,
      learnedWordsCount: 2,
      learningWordsCount: 1,
      starredWordsCount: 1,
      levelProgressList: [
        LevelProgressData(
          levelCode: 'b1',
          levelName: 'Intermediate',
          progress: 0.5,
          knownTerms: 2,
          totalTerms: 4,
        ),
      ],
      examCount: 1,
      averageExamScore: 0.8,
      strongestUnits: [
        UnitProgressData(unitId: 'b1-0', unitName: 'Travel', progress: 0.75),
      ],
      weakestUnits: [
        UnitProgressData(unitId: 'b1-1', unitName: 'Food', progress: 0.25),
      ],
      recentExams: [],
      recentCoachFeedback: [],
    );
  }
}

ExamConfig sampleExamConfig({
  String levelCode = 'b1',
  String unitName = 'Travel',
  String unitId = 'b1-0',
}) {
  return ExamConfig(
    levelCode: levelCode,
    unitName: unitName,
    unitId: unitId,
    unitLabel: unitName,
    starOnly: false,
    questionCount: 1,
    enabledTypes: const {ExamQuestionType.termToDefinition},
  );
}

ExamPaper sampleExamPaper({ExamConfig? config}) {
  final resolvedConfig = config ?? sampleExamConfig();
  return ExamPaper(
    id: 'exam_test',
    config: resolvedConfig,
    questions: [
      ExamQuestion(
        id: 'q1',
        type: ExamQuestionType.termToDefinition,
        prompt: 'Pick the correct definition',
        termId: 'hello',
        termText: 'hello',
        definition: 'greeting',
        options: const ['greeting', 'goodbye', 'thanks', 'sorry'],
        correctAnswer: 'greeting',
      ),
    ],
    createdAt: DateTime(2026, 1, 1),
  );
}

ExamResult sampleExamResult({ExamPaper? paper}) {
  final resolvedPaper = paper ?? sampleExamPaper();
  final question = resolvedPaper.questions.first;
  return ExamResult(
    examId: resolvedPaper.id,
    paper: resolvedPaper,
    answers: [
      GradedAnswer(
        question: question,
        userAnswer: 'greeting',
        isCorrect: true,
      ),
    ],
    correctCount: 1,
    wrongCount: 0,
    percentage: 100,
    completedAt: DateTime(2026, 1, 1),
  );
}

ExamHistoryDetail sampleExamHistoryDetail({String id = 'exam_hist_1'}) {
  return ExamHistoryDetail(
    id: id,
    date: DateTime(2026, 1, 1),
    unitId: 'b1-0',
    unitLabel: 'Travel',
    score: 80,
    questionCount: 1,
    questions: const [
      ExamHistoryQuestion(
        type: ExamQuestionType.termToDefinition,
        question: 'hello',
        userAnswer: 'greeting',
        correctAnswer: 'greeting',
        isCorrect: true,
      ),
    ],
  );
}

CoachSession sampleCoachSession({int wordCount = 1}) {
  return CoachSession(
    config: CoachSessionConfig(
      levelCodes: const ['b1'],
      unitKeys: const ['b1|Travel'],
      starFilter: CoachStarFilter.all,
      wordCount: wordCount,
    ),
    words: [
      for (var i = 0; i < wordCount; i++)
        CoachWord(
          levelCode: 'b1',
          unitName: 'Travel',
          unitId: 'b1-0',
          term: Term(
            id: 'hello$i',
            text: 'hello',
            definition: 'greeting',
          ),
        ),
    ],
  );
}

CoachHistoryTerm sampleCoachHistoryTerm({String termId = 'hello'}) {
  return CoachHistoryTerm(
    unitId: 'b1-0',
    termId: termId,
    levelCode: 'b1',
    unitName: 'Travel',
    definition: 'greeting',
    lastCoachedAt: DateTime(2026, 1, 1, 12, 0),
    feedbackCount: 2,
  );
}

class FakeExamService implements IExamService {
  ExamPaper? _paper;
  ExamResult? _result;
  bool _generating = false;
  final List<ExamHistorySummary> history = [];
  final Map<String, ExamHistoryDetail> historyDetails = {};
  ExamConfig? lastConfig;

  void seedPaper(ExamPaper paper) {
    _paper = paper;
    _result = null;
  }

  void seedResult(ExamResult result) {
    _result = result;
    _paper = result.paper;
  }

  @override
  ExamPaper? get currentPaper => _paper;

  @override
  ExamResult? get currentResult => _result;

  @override
  bool get isGenerating => _generating;

  @override
  Future<ExamPaper> prepareExam(ExamConfig config) async {
    lastConfig = config;
    _generating = true;
    _result = null;
    _paper ??= sampleExamPaper(config: config);
    _generating = false;
    return _paper!;
  }

  @override
  Future<ExamResult> submitExam(Map<String, String?> answersByQuestionId) async {
    if (_paper == null) {
      throw StateError('No active exam paper.');
    }
    _result = sampleExamResult(paper: _paper);
    return _result!;
  }

  @override
  void clearSession() {
    _paper = null;
    _result = null;
  }

  @override
  Future<List<ExamHistorySummary>> getHistory() async => history;

  @override
  Future<ExamHistoryDetail?> getHistoryDetail(String examId) async =>
      historyDetails[examId];

  @override
  Future<void> deleteHistory(String examId) async {
    history.removeWhere((item) => item.id == examId);
    historyDetails.remove(examId);
  }
}

class FakeCoachService implements ICoachService {
  CoachSession? _session;
  List<CoachHistoryTerm> coachedTerms = [];
  bool throwOnExplain = false;
  bool throwOnEvaluate = false;

  void seedSession(CoachSession session) {
    _session = session;
  }

  @override
  CoachSession? get currentSession => _session;

  @override
  Future<int> countAvailableWords(CoachSessionConfig config) async =>
      _session?.words.length ?? 5;

  @override
  Future<void> startSession(CoachSessionConfig config) async {}

  @override
  void clearSession() {
    _session = null;
  }

  @override
  Future<CoachExplainResult> getExplanation(CoachWord word) async {
    if (throwOnExplain) {
      throw Exception('Explain failed');
    }
    return CoachExplainResult(
      usage: 'Common greeting',
      contexts: const ['daily life'],
      examples: [
        CoachExplainExample(
          sentence: 'I say ${word.term.text} every morning.',
          note: 'Basic usage',
        ),
      ],
    );
  }

  @override
  Future<CoachEvaluateResult> evaluateSentence({
    required CoachWord word,
    required String sentence,
  }) async {
    if (throwOnEvaluate) {
      throw Exception('Evaluate failed');
    }
    return const CoachEvaluateResult(
      grammar: 'Good',
      vocabulary: 'Good',
      naturalness: 'Natural',
      suggestions: ['Nice sentence'],
      rawJson: {},
    );
  }

  @override
  Future<void> saveCoachFeedback({
    required CoachWord word,
    required String userSentence,
    required CoachEvaluateResult result,
  }) async {}

  @override
  Future<List<CoachHistoryTerm>> loadCoachedTerms() async => coachedTerms;

  @override
  Future<CoachHistoryTermDetail?> loadCoachedTermDetail({
    required String unitId,
    required String termId,
  }) async =>
      null;

  @override
  Future<List<CoachFeedbackEntry>> loadFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) async =>
      const [];

  @override
  Future<CoachFeedbackEntry?> loadFeedback(String feedbackId) async => null;

  @override
  Future<void> deleteFeedback(String feedbackId) async {}

  @override
  Future<void> deleteAllFeedbacksForTerm({
    required String unitId,
    required String termId,
  }) async {
    coachedTerms.removeWhere(
      (term) => term.unitId == unitId && term.termId == termId,
    );
  }
}

class FailingWordStateRepository implements IWordStateRepository {
  FailingWordStateRepository(this._delegate);

  final IWordStateRepository _delegate;
  bool failNextUpdate = false;

  @override
  Future<List<UserWordState>> getByUnit(String unitId) =>
      _delegate.getByUnit(unitId);

  @override
  Future<UserWordState?> getByTerm({
    required String unitId,
    required String termId,
  }) =>
      _delegate.getByTerm(unitId: unitId, termId: termId);

  @override
  Future<void> save(UserWordState state) async {
    if (failNextUpdate) {
      failNextUpdate = false;
      throw Exception('Persist failed');
    }
    return _delegate.save(state);
  }

  @override
  Future<void> toggleStar({
    required String unitId,
    required String termId,
  }) async {
    if (failNextUpdate) {
      failNextUpdate = false;
      throw Exception('Persist failed');
    }
    return _delegate.toggleStar(unitId: unitId, termId: termId);
  }

  @override
  Future<void> updateStatus({
    required String unitId,
    required String termId,
    required WordStatus status,
  }) async {
    if (failNextUpdate) {
      failNextUpdate = false;
      throw Exception('Persist failed');
    }
    return _delegate.updateStatus(
      unitId: unitId,
      termId: termId,
      status: status,
    );
  }
}
