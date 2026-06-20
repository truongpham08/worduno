abstract class IExamAiDataSource {
  Future<Map<String, dynamic>> generateClozeQuestion({
    required String term,
    required String definition,
  });

  Future<bool> evaluateEnglishToVietnamese({
    required String term,
    required String userAnswer,
  });

  Future<Map<String, dynamic>> evaluateSentenceWriting({
    required String term,
    required String userSentence,
  });
}
