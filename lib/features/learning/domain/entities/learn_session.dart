import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../../../../shared/word_state/domain/entities/word_status.dart';

/// A status restore instruction produced by [LearnSession.undo].
typedef LearnStatusRestore = ({String termId, WordStatus status});

/// Pure, framework-free model of a Learn session and its session rule (spec §6):
///
/// * Terms marked **Learning** reappear after the current round is finished.
/// * The session is only **complete** when every term is **Known**.
///
/// The session owns the queue ordering and undo logic. It does not touch any
/// repository or database; persistence is the caller's responsibility.
class LearnSession {
  LearnSession._(this._round, this._next, this._statuses, this.totalCards);

  /// Builds a session from [terms]. Terms already [WordStatus.know] are
  /// considered done and excluded from the working queue. When [startTermId]
  /// is provided the queue is rotated so that term is shown first.
  factory LearnSession.fromTerms({
    required List<Term> terms,
    required Map<String, WordStatus> initialStatuses,
    String? startTermId,
  }) {
    final statuses = <String, WordStatus>{
      for (final term in terms)
        term.id: initialStatuses[term.id] ?? WordStatus.newWord,
    };

    var round = terms
        .where((term) => statuses[term.id] != WordStatus.know)
        .toList(growable: true);

    if (startTermId != null && startTermId.isNotEmpty) {
      final index = round.indexWhere((term) => term.id == startTermId);
      if (index > 0) {
        round = [...round.sublist(index), ...round.sublist(0, index)];
      } else if (index == -1) {
        final match = terms.where((term) => term.id == startTermId).toList();
        if (match.isNotEmpty) {
          round.insert(0, match.first);
        }
      }
    }

    return LearnSession._(round, <Term>[], statuses, terms.length);
  }

  List<Term> _round;
  List<Term> _next;
  final Map<String, WordStatus> _statuses;
  final int totalCards;

  final List<_SessionSnapshot> _undoStack = [];

  /// The card currently being studied, or `null` when the session is complete.
  Term? get currentTerm => _round.isEmpty ? null : _round.first;

  bool get isCompleted => _round.isEmpty && _next.isEmpty;

  bool get canUndo => _undoStack.isNotEmpty;

  /// Number of terms currently in the [WordStatus.know] state.
  int get knownCount =>
      _statuses.values.where((status) => status == WordStatus.know).length;

  /// Progress as the fraction of known terms (BR-07).
  double get progress => totalCards == 0 ? 0 : knownCount / totalCards;

  WordStatus statusOf(String termId) =>
      _statuses[termId] ?? WordStatus.newWord;

  /// Marks the current term as Known and advances. Returns the affected term.
  Term markKnow() => _advance(WordStatus.know, requeue: false);

  /// Marks the current term as Learning (it reappears next round). Returns it.
  Term markLearning() => _advance(WordStatus.learning, requeue: true);

  Term _advance(WordStatus status, {required bool requeue}) {
    assert(_round.isNotEmpty, 'No current card to advance.');
    _snapshot();

    final term = _round.removeAt(0);
    _statuses[term.id] = status;
    if (requeue) {
      _next.add(term);
    }

    // When the current round is exhausted, promote the requeued (Learning)
    // cards into a new round so they reappear (spec §6).
    if (_round.isEmpty && _next.isNotEmpty) {
      _round = _next;
      _next = <Term>[];
    }

    return term;
  }

  /// Reverts the last mark. Returns the term + status to re-persist, or `null`.
  LearnStatusRestore? undo() {
    if (_undoStack.isEmpty) return null;

    final snapshot = _undoStack.removeLast();
    _round = snapshot.round;
    _next = snapshot.next;
    _statuses[snapshot.termId] = snapshot.previousStatus;

    return (termId: snapshot.termId, status: snapshot.previousStatus);
  }

  /// Shuffles the remaining cards in the current round. Clears undo history.
  void shuffle() {
    _round.shuffle();
    _undoStack.clear();
  }

  void _snapshot() {
    final term = _round.first;
    _undoStack.add(
      _SessionSnapshot(
        round: List.of(_round),
        next: List.of(_next),
        termId: term.id,
        previousStatus: statusOf(term.id),
      ),
    );
  }
}

class _SessionSnapshot {
  _SessionSnapshot({
    required this.round,
    required this.next,
    required this.termId,
    required this.previousStatus,
  });

  final List<Term> round;
  final List<Term> next;
  final String termId;
  final WordStatus previousStatus;
}
