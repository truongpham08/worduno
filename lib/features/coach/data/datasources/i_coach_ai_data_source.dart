abstract class ICoachAiDataSource {
  Future<Map<String, dynamic>> explainWord({
    required String word,
    required String definition,
  });

  Future<Map<String, dynamic>> evaluateSentence({
    required String word,
    required String sentence,
  });
}
