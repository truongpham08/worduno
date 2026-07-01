import 'word_status.dart';

class UserWordState {
  const UserWordState({
    required this.unitId,
    required this.termId,
    required this.isStarred,
    required this.status,
    this.explanation,
  });

  final String unitId;
  final String termId;
  final bool isStarred;
  final WordStatus status;
  final String? explanation;

  UserWordState copyWith({
    bool? isStarred,
    WordStatus? status,
    String? explanation,
    bool clearExplanation = false,
  }) {
    return UserWordState(
      unitId: unitId,
      termId: termId,
      isStarred: isStarred ?? this.isStarred,
      status: status ?? this.status,
      explanation: clearExplanation ? null : explanation ?? this.explanation,
    );
  }
}
