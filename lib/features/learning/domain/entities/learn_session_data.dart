import '../../../../shared/vocabulary/domain/entities/term.dart';
import '../../../../shared/word_state/domain/entities/user_word_state.dart';

/// Everything needed to start a Learn session: the resolved unit id, the terms
/// to study, and their currently persisted states (keyed by term id).
class LearnSessionData {
  const LearnSessionData({
    required this.unitId,
    required this.terms,
    required this.states,
  });

  final String unitId;
  final List<Term> terms;
  final Map<String, UserWordState> states;
}
