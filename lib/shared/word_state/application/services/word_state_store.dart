import 'package:flutter/foundation.dart';

import '../../domain/entities/user_word_state.dart';
import '../../domain/entities/word_status.dart';
import '../../domain/repositories/i_word_state_repository.dart';

/// Reactive, in-memory source of truth for user word states.
///
/// Wraps the SQLite-backed [IWordStateRepository] with a cache and notifies
/// listeners whenever a state changes, so any UI bound to it updates instantly.
///
/// Writes are write-through: the cache is updated optimistically, the change is
/// persisted, and on failure the cache is rolled back and the error rethrown —
/// the UI therefore never shows a state that was not actually persisted.
class WordStateStore extends ChangeNotifier {
  WordStateStore(this._repository);

  final IWordStateRepository _repository;

  final Map<String, Map<String, UserWordState>> _byUnit = {};

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  /// Loads the states for [unitId] into the cache. Subsequent calls are no-ops
  /// unless [forceReload] is set (used to pick up changes made elsewhere).
  Future<void> ensureLoaded(String unitId, {bool forceReload = false}) async {
    if (unitId.isEmpty) return;
    if (!forceReload && _byUnit.containsKey(unitId)) return;

    final states = await _repository.getByUnit(unitId);
    _byUnit[unitId] = {for (final state in states) state.termId: state};
    notifyListeners();
  }

  List<UserWordState> statesOf(String unitId) =>
      _byUnit[unitId]?.values.toList(growable: false) ?? const [];

  UserWordState stateFor({required String unitId, required String termId}) {
    return _byUnit[unitId]?[termId] ??
        UserWordState(
          unitId: unitId,
          termId: termId,
          isStarred: false,
          status: WordStatus.newWord,
        );
  }

  int knownCount(String unitId) =>
      statesOf(unitId).where((s) => s.status == WordStatus.know).length;

  Future<void> updateStatus({
    required String unitId,
    required String termId,
    required WordStatus status,
  }) async {
    final previous = stateFor(unitId: unitId, termId: termId);
    _put(previous.copyWith(status: status));
    notifyListeners();

    try {
      await _repository.updateStatus(
        unitId: unitId,
        termId: termId,
        status: status,
      );
    } catch (_) {
      _put(previous);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveExplanation({
    required String unitId,
    required String termId,
    required String explanationJson,
  }) async {
    final previous = stateFor(unitId: unitId, termId: termId);
    final next = previous.copyWith(explanation: explanationJson);
    _put(next);
    notifyListeners();

    try {
      await _repository.save(next);
    } catch (_) {
      _put(previous);
      notifyListeners();
      rethrow;
    }
  }

  /// Ensures a row exists in SQLite for the FK used by coach feedback.
  Future<void> ensurePersisted({
    required String unitId,
    required String termId,
  }) async {
    await ensureLoaded(unitId);
    final existing = await _repository.getByTerm(
      unitId: unitId,
      termId: termId,
    );
    if (existing != null) {
      return;
    }

    await _repository.save(stateFor(unitId: unitId, termId: termId));
  }

  Future<void> toggleStar({
    required String unitId,
    required String termId,
  }) async {
    final previous = stateFor(unitId: unitId, termId: termId);
    _put(previous.copyWith(isStarred: !previous.isStarred));
    notifyListeners();

    try {
      await _repository.toggleStar(unitId: unitId, termId: termId);
    } catch (_) {
      _put(previous);
      notifyListeners();
      rethrow;
    }
  }

  void _put(UserWordState state) {
    final unit = _byUnit.putIfAbsent(state.unitId, () => <String, UserWordState>{});
    unit[state.termId] = state;
  }
}
