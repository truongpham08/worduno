import 'package:flutter/foundation.dart';

import '../../../../app/di/injection.dart';
import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../../../../shared/word_state/application/services/word_state_store.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';
import '../../application/services/i_learn_service.dart';
import '../../domain/entities/learn_session.dart';

class LearnSessionViewModel extends ChangeNotifier {
  LearnSessionViewModel({
    required this.levelCode,
    required this.unitName,
    String? unitId,
    this.initialTermId,
    ILearnService? learnService,
    WordStateStore? wordStateStore,
  })  : _learnService = learnService ?? getIt<ILearnService>(),
        _store = wordStateStore ?? getIt<WordStateStore>(),
        _unitId = unitId ?? '' {
    _store.addListener(_onStoreChanged);
  }

  final String levelCode;
  final String unitName;
  final String? initialTermId;
  final ILearnService _learnService;
  final WordStateStore _store;

  String _unitId;
  String get unitId => _unitId;

  bool _isDisposed = false;

  bool isLoading = false;
  String? errorMessage;
  bool isFlipped = false;

  LearnSession? _session;

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

  // ── Derived state for the view ────────────────────────────────────────────
  bool get isEmptySession => _session != null && _session!.totalCards == 0;
  bool get isCompleted => _session?.isCompleted ?? false;
  Term? get currentTerm => _session?.currentTerm;
  bool get canUndo => _session?.canUndo ?? false;
  double get progress => _session?.progress ?? 0;
  int get knownCount => _session?.knownCount ?? 0;
  int get totalCards => _session?.totalCards ?? 0;
  String get progressLabel => '$knownCount/$totalCards';

  bool get currentStarred {
    final term = currentTerm;
    if (term == null) return false;
    return _store.stateFor(unitId: _unitId, termId: term.id).isStarred;
  }

  Future<void> loadSession() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _learnService.loadSessionData(
        levelCode: levelCode,
        unitName: unitName,
        unitId: _unitId.isEmpty ? null : _unitId,
      );
      _unitId = data.unitId;
      _session = LearnSession.fromTerms(
        terms: data.terms,
        initialStatuses: {
          for (final entry in data.states.entries) entry.key: entry.value.status,
        },
        startTermId: initialTermId,
      );
      isFlipped = false;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void flipCard() {
    isFlipped = !isFlipped;
    notifyListeners();
  }

  Future<void> markKnow() => _mark(WordStatus.know);

  Future<void> markLearning() => _mark(WordStatus.learning);

  Future<void> _mark(WordStatus status) async {
    final session = _session;
    if (session == null || session.currentTerm == null) return;

    final term =
        status == WordStatus.know ? session.markKnow() : session.markLearning();
    isFlipped = false;
    notifyListeners();

    try {
      await _learnService.markStatus(
        unitId: _unitId,
        termId: term.id,
        status: status,
      );
    } catch (error) {
      debugPrint('LearnSession: failed to persist status for ${term.id}: $error');
    }
  }

  Future<void> toggleStarCurrent() async {
    final term = currentTerm;
    if (term == null || _unitId.isEmpty) return;

    try {
      await _learnService.toggleStar(unitId: _unitId, termId: term.id);
    } catch (error) {
      debugPrint('LearnSession: failed to toggle star for ${term.id}: $error');
    }
  }

  Future<void> undo() async {
    final session = _session;
    if (session == null) return;

    final restored = session.undo();
    isFlipped = false;
    notifyListeners();

    if (restored != null) {
      try {
        await _learnService.markStatus(
          unitId: _unitId,
          termId: restored.termId,
          status: restored.status,
        );
      } catch (error) {
        debugPrint('LearnSession: failed to persist undo for ${restored.termId}: $error');
      }
    }
  }

  void shuffle() {
    _session?.shuffle();
    isFlipped = false;
    notifyListeners();
  }
}
