import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../application/services/i_exam_service.dart';
import '../../domain/entities/exam_config.dart';
import '../../domain/entities/exam_history.dart';
import '../../domain/entities/exam_paper.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/entities/exam_question_type.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/level.dart';
import '../../../../shared/vocabulary/domain/entities/unit.dart';

class ExamConfigViewModel extends ChangeNotifier {
  ExamConfigViewModel({
    this.initialLevelCode,
    this.initialUnitName,
    this.initialUnitId,
    IVocabularyService? vocabularyService,
    IExamService? examService,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _examService = examService ?? getIt<IExamService>() {
    if (initialLevelCode != null) {
      selectedLevelCode = initialLevelCode!;
    }
    if (initialUnitName != null) {
      selectedUnitName = initialUnitName;
      selectedUnitId = initialUnitId;
    }
  }

  final IVocabularyService _vocabularyService;
  final IExamService _examService;

  final String? initialLevelCode;
  final String? initialUnitName;
  final String? initialUnitId;

  bool isLoading = false;
  bool isStarting = false;
  String? errorMessage;

  List<Level> levels = const [];
  List<Unit> units = const [];

  String selectedLevelCode = '';
  String? selectedUnitName;
  String? selectedUnitId;
  bool allUnits = true;
  bool starOnly = false;
  int questionCount = 10;
  Set<ExamQuestionType> enabledTypes = ExamQuestionType.defaults.toSet();

  bool get canStart =>
      selectedLevelCode.isNotEmpty &&
      enabledTypes.isNotEmpty &&
      !isStarting &&
      !isLoading;

  Future<void> initialize() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      levels = await _vocabularyService.getLevels();
      if (selectedLevelCode.isEmpty && levels.isNotEmpty) {
        selectedLevelCode = levels.first.code;
      }
      await _loadUnits();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectLevel(String levelCode) async {
    selectedLevelCode = levelCode;
    allUnits = true;
    selectedUnitName = null;
    selectedUnitId = null;
    await _loadUnits();
  }

  Future<void> _loadUnits() async {
    if (selectedLevelCode.isEmpty) {
      units = const [];
      notifyListeners();
      return;
    }

    try {
      units = await _vocabularyService.getUnits(selectedLevelCode);
      if (!allUnits &&
          selectedUnitName != null &&
          !units.any((unit) => unit.name == selectedUnitName)) {
        selectedUnitName = units.isEmpty ? null : units.first.name;
        selectedUnitId = units.isEmpty ? null : units.first.id;
      }
    } catch (error) {
      errorMessage = error.toString();
    }
    notifyListeners();
  }

  void setAllUnits(bool value) {
    allUnits = value;
    if (allUnits) {
      selectedUnitName = null;
      selectedUnitId = null;
    } else if (units.isNotEmpty) {
      selectedUnitName = units.first.name;
      selectedUnitId = units.first.id;
    }
    notifyListeners();
  }

  void selectUnit(Unit unit) {
    allUnits = false;
    selectedUnitName = unit.name;
    selectedUnitId = unit.id;
    notifyListeners();
  }

  void setStarOnly(bool value) {
    starOnly = value;
    notifyListeners();
  }

  void setQuestionCount(int value) {
    questionCount = value;
    notifyListeners();
  }

  void toggleQuestionType(ExamQuestionType type, bool enabled) {
    if (enabled) {
      enabledTypes = {...enabledTypes, type};
    } else if (enabledTypes.length > 1) {
      enabledTypes = enabledTypes.where((item) => item != type).toSet();
    }
    notifyListeners();
  }

  ExamConfig buildConfig() {
    final unitLabel = allUnits
        ? 'All units • $selectedLevelCode'
        : selectedUnitName ?? 'Unit';

    return ExamConfig(
      levelCode: selectedLevelCode,
      unitName: allUnits ? null : selectedUnitName,
      unitId: allUnits ? 'all' : (selectedUnitId ?? ''),
      unitLabel: unitLabel,
      starOnly: starOnly,
      questionCount: questionCount,
      enabledTypes: enabledTypes,
    );
  }

  Future<ExamPaper> startExam() async {
    isStarting = true;
    errorMessage = null;
    notifyListeners();

    try {
      return await _examService.prepareExam(buildConfig());
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isStarting = false;
      notifyListeners();
    }
  }
}

class ExamSessionViewModel extends ChangeNotifier {
  ExamSessionViewModel({IExamService? examService})
      : _examService = examService ?? getIt<IExamService>();

  final IExamService _examService;

  bool isSubmitting = false;
  String? errorMessage;
  final Map<String, String> _answers = {};

  ExamPaper? get paper => _examService.currentPaper;
  Map<String, String> get answers => Map.unmodifiable(_answers);

  void setAnswer(String questionId, String value) {
    _answers[questionId] = value;
    notifyListeners();
  }

  void setMatchingAnswer(String questionId, Map<String, String> pairs) {
    _answers[questionId] = jsonEncode(pairs);
    notifyListeners();
  }

  Future<void> submit() async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _examService.submitExam(
        Map.fromEntries(
          paper!.questions.map(
            (question) => MapEntry(question.id, _answers[question.id]),
          ),
        ),
      );
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}

class ExamResultViewModel extends ChangeNotifier {
  ExamResultViewModel({IExamService? examService})
      : _examService = examService ?? getIt<IExamService>();

  final IExamService _examService;

  bool reviewMode = false;

  ExamResult? get result => _examService.currentResult;

  void toggleReview() {
    reviewMode = !reviewMode;
    notifyListeners();
  }
}

class ExamHistoryViewModel extends ChangeNotifier {
  ExamHistoryViewModel({IExamService? examService})
      : _examService = examService ?? getIt<IExamService>();

  final IExamService _examService;

  bool isLoading = false;
  String? errorMessage;
  List<ExamHistorySummary> items = const [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      items = await _examService.getHistory();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExam(String examId) async {
    await _examService.deleteHistory(examId);
    await load();
  }
}

class ExamDetailViewModel extends ChangeNotifier {
  ExamDetailViewModel({
    required this.examId,
    IExamService? examService,
  }) : _examService = examService ?? getIt<IExamService>();

  final String examId;
  final IExamService _examService;

  bool isLoading = false;
  String? errorMessage;
  ExamHistoryDetail? detail;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      detail = await _examService.getHistoryDetail(examId);
      if (detail == null) {
        errorMessage = 'Exam not found.';
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExam() async {
    await _examService.deleteHistory(examId);
  }
}
