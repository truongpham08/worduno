import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/level.dart';
import '../../application/services/i_coach_service.dart';
import '../../data/repositories/coach_repository_impl.dart';
import '../../domain/entities/coach_entities.dart';
import '../../domain/entities/coach_star_filter.dart';

class UnitOption {
  const UnitOption({
    required this.key,
    required this.label,
    required this.levelCode,
    required this.unitName,
  });

  final String key;
  final String label;
  final String levelCode;
  final String unitName;
}

class CoachConfigViewModel extends ChangeNotifier {
  CoachConfigViewModel({
    String? levelCode,
    String? unitName,
    String? unitId,
    IVocabularyService? vocabularyService,
    ICoachService? coachService,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _coachService = coachService ?? getIt<ICoachService>(),
        fixedLevelCode = levelCode,
        fixedUnitName = unitName,
        fixedUnitId = unitId {
    _init();
  }

  final IVocabularyService _vocabularyService;
  final ICoachService _coachService;

  final String? fixedLevelCode;
  final String? fixedUnitName;
  final String? fixedUnitId;

  bool get isUnitScoped =>
      fixedLevelCode != null && fixedUnitName != null;

  bool _isDisposed = false;
  bool isLoading = true;
  bool isPoolCountLoading = false;
  bool isStarting = false;
  String? initErrorMessage;
  String? poolCountError;

  List<Level> levels = const [];
  final Set<String> selectedLevelCodes = {};
  bool allLevelsSelected = true;

  List<UnitOption> unitOptions = const [];
  String? selectedUnitKey;
  bool allUnitsSelected = true;

  CoachStarFilter starFilter = CoachStarFilter.all;
  int wordCount = 5;
  int availableWordCount = 0;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> reload() => _init();

  bool get isWideOpenSelection =>
      !isUnitScoped && allLevelsSelected && allUnitsSelected;

  Future<void> _init() async {
    isLoading = true;
    initErrorMessage = null;
    poolCountError = null;
    notifyListeners();

    try {
      if (isUnitScoped) {
        await _refreshPoolCount();
      } else {
        levels = await _vocabularyService.getLevels();
        await _loadUnitOptions();
        if (!isWideOpenSelection) {
          await _refreshPoolCount();
        }
      }
    } catch (error) {
      initErrorMessage = messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLevel(String code) async {
    if (allLevelsSelected) {
      allLevelsSelected = false;
      selectedLevelCodes
        ..clear()
        ..add(code);
    } else if (selectedLevelCodes.contains(code)) {
      selectedLevelCodes.remove(code);
      if (selectedLevelCodes.isEmpty) {
        allLevelsSelected = true;
      }
    } else {
      selectedLevelCodes.add(code);
      if (selectedLevelCodes.length == levels.length) {
        allLevelsSelected = true;
        selectedLevelCodes.clear();
      }
    }

    selectedUnitKey = null;
    allUnitsSelected = true;
    await _loadUnitOptions();
    if (isWideOpenSelection) {
      availableWordCount = 0;
      notifyListeners();
    } else {
      await _refreshPoolCount();
    }
  }

  Future<void> retryPoolCount() => _refreshPoolCount();

  Future<void> selectAllLevels() async {
    allLevelsSelected = true;
    selectedLevelCodes.clear();
    selectedUnitKey = null;
    allUnitsSelected = true;
    await _loadUnitOptions();
    if (isWideOpenSelection) {
      availableWordCount = 0;
      notifyListeners();
    } else {
      await _refreshPoolCount();
    }
  }

  Future<void> selectUnit(String? key) async {
    if (key == null) {
      allUnitsSelected = true;
      selectedUnitKey = null;
    } else {
      allUnitsSelected = false;
      selectedUnitKey = key;
    }
    if (isWideOpenSelection) {
      availableWordCount = 0;
      notifyListeners();
    } else {
      await _refreshPoolCount();
    }
  }

  Future<void> setStarFilter(CoachStarFilter filter) async {
    starFilter = filter;
    if (isWideOpenSelection) {
      notifyListeners();
      return;
    }
    await _refreshPoolCount();
  }

  void setWordCount(int value) {
    final clamped = value.clamp(1, availableWordCount > 0 ? availableWordCount : 1);
    if (wordCount != clamped) {
      wordCount = clamped;
      notifyListeners();
    }
  }

  CoachSessionConfig buildConfig() {
    if (isUnitScoped) {
      return CoachSessionConfig(
        levelCodes: [fixedLevelCode!],
        unitKeys: const [],
        starFilter: starFilter,
        wordCount: wordCount,
        fixedLevelCode: fixedLevelCode,
        fixedUnitName: fixedUnitName,
        fixedUnitId: fixedUnitId,
      );
    }

    return CoachSessionConfig(
      levelCodes: _resolvedLevelCodes(),
      unitKeys: allUnitsSelected || selectedUnitKey == null
          ? const []
          : [selectedUnitKey!],
      starFilter: starFilter,
      wordCount: wordCount,
    );
  }

  /// When a specific unit is chosen, scope to its level even if "All levels" is on.
  List<String> _resolvedLevelCodes() {
    if (!allLevelsSelected) {
      return selectedLevelCodes.toList();
    }
    if (!allUnitsSelected && selectedUnitKey != null) {
      final option = unitOptions
          .where((unit) => unit.key == selectedUnitKey)
          .firstOrNull;
      if (option != null) {
        return [option.levelCode];
      }
      final separator = selectedUnitKey!.indexOf('|');
      if (separator > 0) {
        return [selectedUnitKey!.substring(0, separator)];
      }
    }
    return const [];
  }

  Future<void> startSession() async {
    isStarting = true;
    poolCountError = null;
    notifyListeners();

    try {
      if (availableWordCount == 0) {
        await _refreshPoolCount();
      }
      if (availableWordCount == 0) {
        poolCountError = poolCountError ??
            'No words available for the selected filters.';
        return;
      }

      await _coachService.startSession(buildConfig());
    } catch (error) {
      poolCountError = messageFromError(error);
      rethrow;
    } finally {
      isStarting = false;
      notifyListeners();
    }
  }

  Future<void> _loadUnitOptions() async {
    final activeLevels = allLevelsSelected
        ? levels.map((l) => l.code).toList()
        : selectedLevelCodes.toList();

    final showPrefix = activeLevels.length > 1;
    final options = <UnitOption>[];

    for (final levelCode in activeLevels) {
      final units = await _vocabularyService.getUnits(levelCode);
      for (final unit in units) {
        options.add(
          UnitOption(
            key: CoachRepositoryImpl.unitKey(levelCode, unit.name),
            label: CoachRepositoryImpl.unitLabel(
              levelCode: levelCode,
              unitName: unit.name,
              showLevelPrefix: showPrefix,
            ),
            levelCode: levelCode,
            unitName: unit.name,
          ),
        );
      }
    }

    unitOptions = options;
    notifyListeners();
  }

  Future<void> _refreshPoolCount() async {
    isPoolCountLoading = true;
    poolCountError = null;
    notifyListeners();

    try {
      availableWordCount = await _coachService.countAvailableWords(buildConfig());
      if (availableWordCount > 0) {
        wordCount = wordCount.clamp(1, availableWordCount);
      }
    } catch (error) {
      availableWordCount = 0;
      poolCountError = messageFromError(error);
    } finally {
      isPoolCountLoading = false;
      notifyListeners();
    }
  }
}
