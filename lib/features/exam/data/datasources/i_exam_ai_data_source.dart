import '../dtos/exam_ai_dtos.dart';

abstract class IExamAiDataSource {
  Future<ClozeResponseDto> generateCloze({
    required String word,
    required String definition,
    required String level,
  });

  Future<EvaluateSentenceResponseDto> evaluateSentenceWriting({
    required String word,
    required String definition,
    required String sentence,
  });
}
