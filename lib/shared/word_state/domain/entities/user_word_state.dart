import 'word_status.dart';

class UserWordState {
  const UserWordState({
    required this.unitId,
    required this.termId,
    required this.isStarred,
    required this.status,
  });

  final String unitId;
  final String termId;
  final bool isStarred;
  final WordStatus status;

  UserWordState copyWith({
    bool? isStarred,
    WordStatus? status,
  }) {
    return UserWordState(
      unitId: unitId,
      termId: termId,
      isStarred: isStarred ?? this.isStarred,
      status: status ?? this.status,
    );
  }
}
