import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/level.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';

class LevelListViewModel extends ChangeNotifier {
  LevelListViewModel({
    IVocabularyService? vocabularyService,
    WordStateStore? wordStateStore,
    AppDatabase? database,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _store = wordStateStore ?? getIt<WordStateStore>(),
        _database = database ?? getIt<AppDatabase>() {
    _store.addListener(_onStoreChanged);
  }

  static const _termFetchConcurrency = 4;

  final IVocabularyService _vocabularyService;
  final WordStateStore _store;
  final AppDatabase _database;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  bool isLoading = false;
  bool isReloading = false;
  String? errorMessage;
  String? reloadProgress;
  int currentStreak = 0;

  /// Per-level aggregates: code, total terms, and the unit ids that compose it.
  /// Known counts are derived reactively from the [WordStateStore].
  List<_LevelAggregate> _aggregates = const [];

  List<Level> get levels => _aggregates
      .map(
        (agg) => Level(
          code: agg.code,
          totalTerms: agg.totalTerms,
          knownTerms: agg.unitIds.fold<int>(
            0,
            (sum, unitId) => sum + _store.knownCount(unitId),
          ),
        ),
      )
      .toList(growable: false);

  int get totalLearned => _aggregates.fold<int>(
        0,
        (sum, aggregate) =>
            sum +
            aggregate.unitIds.fold<int>(
              0,
              (unitSum, unitId) => unitSum + _store.knownCount(unitId),
            ),
      );

  int get totalStarred => _aggregates.fold<int>(
        0,
        (sum, aggregate) =>
            sum +
            aggregate.unitIds.fold<int>(
              0,
              (unitSum, unitId) => unitSum + _store.starredCount(unitId),
            ),
      );

  Future<void> loadLevels() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _fetchLevels();
    } catch (error) {
      errorMessage = messageFromError(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadLevels() async {
    if (isLoading || isReloading) {
      return;
    }

    isReloading = true;
    errorMessage = null;
    reloadProgress = 'Preparing refresh...';
    notifyListeners();

    try {
      await _vocabularyService.clearCache();
      await _fetchLevels(trackProgress: true);
    } catch (error) {
      errorMessage = messageFromError(error);
    } finally {
      isReloading = false;
      reloadProgress = null;
      notifyListeners();
    }
  }

  Future<void> _fetchLevels({bool trackProgress = false}) async {
    final baseLevels = await _vocabularyService.getLevels();
    final aggregates = <_LevelAggregate>[];

    for (var levelIndex = 0; levelIndex < baseLevels.length; levelIndex++) {
      final level = baseLevels[levelIndex];
      if (trackProgress) {
        reloadProgress =
            'Refreshing ${level.code.toUpperCase()} (${levelIndex + 1}/${baseLevels.length})...';
        notifyListeners();
      }

      final units = await _vocabularyService.getUnits(level.code);
      final stats = await mapLimitedConcurrent(
        units,
        _termFetchConcurrency,
        (unit) async {
          try {
            final terms = await _vocabularyService.getTerms(
              levelCode: level.code,
              unitName: unit.name,
            );
            await _store.ensureLoaded(unit.id);
            return (unit.id, terms.length);
          } catch (_) {
            return (unit.id, 0);
          }
        },
      );

      var totalTerms = 0;
      final unitIds = <String>[];
      for (final stat in stats) {
        unitIds.add(stat.$1);
        totalTerms += stat.$2;
      }

      aggregates.add(
        _LevelAggregate(
          code: level.code,
          totalTerms: totalTerms,
          unitIds: unitIds,
        ),
      );

      if (trackProgress) {
        _aggregates = List<_LevelAggregate>.of(aggregates);
        notifyListeners();
      }
    }

    _aggregates = aggregates;
    currentStreak = await _loadCurrentStreak();
  }

  Future<int> _loadCurrentStreak() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT substr(date, 1, 10) AS day
      FROM (
        SELECT date FROM exam_history
        UNION ALL
        SELECT date FROM coach_feedback
      )
      WHERE date IS NOT NULL AND date != ''
      ORDER BY day DESC
    ''');

    if (rows.isEmpty) {
      return 0;
    }

    final activityDays = rows
        .map((row) => DateTime.tryParse(row['day'] as String? ?? ''))
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();

    if (activityDays.isEmpty) {
      return 0;
    }

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!activityDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (activityDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }
}

class _LevelAggregate {
  const _LevelAggregate({
    required this.code,
    required this.totalTerms,
    required this.unitIds,
  });

  final String code;
  final int totalTerms;
  final List<String> unitIds;
}
