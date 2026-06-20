abstract class ICoachAiDataSource {
  Future<Map<String, dynamic>> evaluateSentence({
    required String word,
    required String userSentence,
  });
}
