import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../shared/vocabulary/application/services/i_vocabulary_service.dart';
import '../../../../shared/vocabulary/domain/entities/level.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';

class LevelListViewModel extends ChangeNotifier {
  LevelListViewModel({
    IVocabularyService? vocabularyService,
    WordStateStore? wordStateStore,
  })  : _vocabularyService = vocabularyService ?? getIt<IVocabularyService>(),
        _store = wordStateStore ?? getIt<WordStateStore>() {
    _store.addListener(_onStoreChanged);
  }

  final IVocabularyService _vocabularyService;
  final WordStateStore _store;

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
  String? errorMessage;

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

  Future<void> loadLevels() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final baseLevels = await _vocabularyService.getLevels();

      final futureAggregates = baseLevels.map((level) async {
        final units = await _vocabularyService.getUnits(level.code);

        var totalTerms = 0;
        final unitIds = <String>[];

        final futureUnitStats = units.map((unit) async {
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
        });

        for (final stat in await Future.wait(futureUnitStats)) {
          unitIds.add(stat.$1);
          totalTerms += stat.$2;
        }

        return _LevelAggregate(
          code: level.code,
          totalTerms: totalTerms,
          unitIds: unitIds,
        );
      });

      _aggregates = await Future.wait(futureAggregates);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
